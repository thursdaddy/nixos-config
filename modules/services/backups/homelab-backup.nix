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
      homelab-backup = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.homelab-backup;

      _gotify-alert = pkgs.writeShellApplication {
        name = "gotify-alert";
        runtimeInputs = with pkgs; [
          curl
          jq
          nettools
          coreutils
        ];
        text = builtins.readFile ./gotify-alert.sh;
      };

    in
    {
      options.mine.services.backups = {
        enable = lib.mkEnableOption "Enable my internal backup stuff";
        nfs-mount = lib.mkOption {
          description = "Enable NFS mount";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
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

        environment.systemPackages = [ homelab-backup ];

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
              ExecStart = "${lib.getExe _gotify-alert} %i";
              EnvironmentFile = config.sops.templates."gotify-backups.env".path;
            };
          };
        };
      };
    };
}
