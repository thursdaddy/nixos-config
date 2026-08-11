_: {
  configurations.nixos.wormhole.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;
    in
    {
      systemd = {
        services.backup-gcloudbox = {
          description = "Reverse tunnel rsync from gcloudbox to ZFS server";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          onFailure = [ "gotify-failure@%N.service" ];
          serviceConfig = {
            Type = "oneshot";
            User = "${user.name}";
            Group = "${user.name}";
            ExecStart = pkgs.writeShellScript "rsync-two-step-script" ''
              mkdir -p /tmp/gcloudbox_staging

              # Pull from gcloudbox (no sudo needed as all directories under /opt/configs/ are readable by thurs)
              ${pkgs.rsync}/bin/rsync -avz --delete -e "${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
                gcloudbox:/opt/configs/ /tmp/gcloudbox_staging/

              # Fetch the exact image of the container running on gcloudbox (without sudo by inspecting systemd unit config)
              GOTIFY_IMAGE=$(${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new gcloudbox "systemctl cat podman-gotify | grep -o '/nix/store/.*-unit-script-podman-gotify-start/bin/podman-gotify-start' | xargs cat | grep -o 'gotify/server:[a-zA-Z0-9.-]*' | head -n 1")
              if [ -z "$GOTIFY_IMAGE" ]; then GOTIFY_IMAGE="gotify/server:unknown"; fi

              # Inject the metadata dynamically into the staging directory before push
              echo '{
                "backup_timestamp": "'$(date -Iseconds)'",
                "configuration": {
                  "target": "opt_configs",
                  "type": "file",
                  "source_path": "/opt/configs",
                  "destination": "thurs@192.168.10.12:/fast/backups/gcloudbox/file/opt/configs",
                  "image": "'$GOTIFY_IMAGE'"
                }
              }' > /tmp/gcloudbox_staging/backup_metadata.json

              # Push to ZFS server (using --mkpath and sudo rsync to bypass root-owned ZFS dataset permissions)
              ${pkgs.rsync}/bin/rsync -avz --delete --mkpath --rsync-path="sudo rsync" -e "${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
                /tmp/gcloudbox_staging/ ${user.name}@192.168.10.12:/fast/backups/gcloudbox/file/opt/configs
            '';
          };
        };

        timers.backup-gcloudbox = {
          description = "Run gcloudbox daily backup";
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
          wantedBy = [ "timers.target" ];
        };
      };

      environment.etc =
        let
          alloyJournal = lib.thurs.mkAlloyJournal {
            name = "backup_gcloudbox";
            serviceName = "backup-gcloudbox";
          };
        in
        {
          "${alloyJournal.name}" = alloyJournal.value;
        };
    };
}
