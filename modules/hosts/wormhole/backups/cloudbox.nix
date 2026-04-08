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
      mine = {
        base = {
          nfs-mounts = {
            enable = true;
            mounts = {
              "/mnt/cloudbox" = {
                device = "192.168.10.12:/fast/backups/cloudbox";
              };
            };
          };
        };
      };
      systemd = {
        services.backup-cloudbox = {
          description = "Rsync files from cloudbox";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          onFailure = [ "gotify-backup-failure@%N.service" ];
          unitConfig = {
            RequiresMountsFor = "/mnt/cloudbox";
          };
          serviceConfig = {
            Type = "oneshot";
            User = "${user.name}";
            Group = "${user.name}";
            ExecStart = pkgs.writeShellScript "rsync-script" ''
              ${pkgs.rsync}/bin/rsync -avz \
                -e "${pkgs.openssh}/bin/ssh" \
                --delete \
                cloudbox:/mnt/backups/ \
                /mnt/cloudbox/
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
