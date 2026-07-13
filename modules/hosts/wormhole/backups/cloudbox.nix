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
        services.backup-cloudbox = {
          description = "Reverse tunnel rsync from cloudbox to ZFS server";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          onFailure = [ "gotify-failure@%N.service" ];
          serviceConfig = {
            Type = "oneshot";
            User = "${user.name}";
            Group = "${user.name}";
            ExecStart = pkgs.writeShellScript "rsync-two-step-script" ''
              mkdir -p /tmp/cloudbox_staging

              # Pull from cloudbox (using sudo rsync to ensure we can read all root-owned config files)
              ${pkgs.rsync}/bin/rsync -avz --delete --rsync-path="sudo rsync" -e "${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
                cloudbox:/opt/configs/ /tmp/cloudbox_staging/

              # Fetch the exact image of the container running on cloudbox
              # Using ps instead of inspect catches it even if the container is named slightly differently
              GOTIFY_IMAGE=$(${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new cloudbox "sudo podman ps -a --format '{{.Image}}' --filter 'name=gotify' 2>/dev/null || sudo docker ps -a --format '{{.Image}}' --filter 'name=gotify' 2>/dev/null" | ${pkgs.gnugrep}/bin/grep "gotify/server" | ${pkgs.coreutils}/bin/head -n 1)
              if [ -z "$GOTIFY_IMAGE" ]; then GOTIFY_IMAGE="gotify/server:unknown"; fi

              # Inject the metadata dynamically into the staging directory before push
              echo '{
                "backup_timestamp": "'$(date -Iseconds)'",
                "configuration": {
                  "target": "opt_configs",
                  "type": "file",
                  "source_path": "/opt/configs",
                  "destination": "thurs@192.168.10.12:/fast/backups/cloudbox/file/opt/configs",
                  "image": "'$GOTIFY_IMAGE'"
                }
              }' > /tmp/cloudbox_staging/backup_metadata.json

              # Push to ZFS server (using --mkpath and sudo rsync to bypass root-owned ZFS dataset permissions)
              ${pkgs.rsync}/bin/rsync -avz --delete --mkpath --rsync-path="sudo rsync" -e "${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new" \
                /tmp/cloudbox_staging/ ${user.name}@192.168.10.12:/fast/backups/cloudbox/file/opt/configs
            '';
          };
        };

        timers.backup-cloudbox = {
          description = "Run cloudbox daily backup";
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
          wantedBy = [ "timers.target" ];
        };
      };
    };
}
