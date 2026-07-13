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
      homelabBackup = pkgs.homelab-backup;
      gotifyAlert = pkgs.gotify-alert;
    in
    {
      options.mine.services.backups = {
        enable = lib.mkEnableOption "Enable backup script";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ homelabBackup ];

        sops = {
          secrets = {
            "gotify/URL" = { };
            "gotify/token/BACKUPS" = { };
          };
          templates = {
            "gotify-backups.env" = {
              owner = "${user.name}";
              content = ''
                GOTIFY_URL="${config.sops.placeholder."gotify/URL"}"
                GOTIFY_APP_TOKEN="${config.sops.placeholder."gotify/token/BACKUPS"}"
              '';
            };
          };
        };

        systemd = {
          services."gotify-failure@" = {
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
