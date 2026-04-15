{ inputs, ... }:
{
  flake.modules.nixos.services =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.mine.services.backups;
      inherit (config.mine.base) user;
      homelabBackup = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.homelab-backup;
      gotifyAlert = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.gotify-alert;
    in
    {
      options.mine.services.backups = {
        enable = lib.mkEnableOption "Enable backup script";
        nfs-mount = lib.mkOption {
          description = "Enable NFS mount";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ homelabBackup ];

        mine = lib.mkIf cfg.nfs-mount {
          base = {
            nfs-mounts = {
              enable = true;
              mounts = {
                "/mnt/backups" = {
                  device = "192.168.10.12:/fast/backups/${config.networking.hostName}";
                };
              };
            };
          };
        };

        sops = {
          secrets = {
            "gotify/URL" = { };
            "gotify/token/BACKUPS" = { };
          };
          templates = {
            "gotify-backups.env" = {
              owner = "${user.name}";
              content = ''
                GOTIFY_URL=${config.sops.placeholder."gotify/URL"}
                GOTIFY_APP_TOKEN=${config.sops.placeholder."gotify/token/BACKUPS"}
              '';
            };
          };
        };

        systemd = {
          services."gotify-backup-failure@" = {
            description = "Runs when a service fails.";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${lib.getExe gotifyAlert} %i";
              EnvironmentFile = config.sops.templates."gotify-backups.env".path;
            };
          };
        };
      };
    };
}
