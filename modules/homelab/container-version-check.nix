{ inputs, ... }:
{
  flake.modules.nixos.services =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (config.mine.base) user;
      cfg = config.mine.homelab.${config.networking.hostName}.services.container-version-check;
      gotifyAlert = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.gotify-alert;
    in
    {
      config = lib.mkMerge [
        {
          programs = lib.mkIf (user.shell.package == pkgs.fish) {
            fish = {
              shellAliases = config.mine.aliases.docker;
            };
          };

          users.users.${user.name}.extraGroups = [ "docker" ];
        }

        (
          let
            containerVersionScript = builtins.readFile ./scripts/container-version-check.py;
            containerVersionCheck = pkgs.writers.writePython3Bin "_container-version-check" {
              flakeIgnore = [
                "W503"
                "E501"
              ];
              libraries = with pkgs.python3Packages; [
                requests
                docker
              ];
            } containerVersionScript;
          in
          lib.mkIf cfg {
            environment.systemPackages = [
              containerVersionCheck
            ];

            systemd = {
              services = {
                container-version-check = {
                  description = "container-version-check";
                  onFailure = [ "gotify-container-check@%n.service" ];
                  serviceConfig = {
                    EnvironmentFile = config.sops.templates."gotify-container-check.env".path;
                    ExecStart = "${lib.getExe containerVersionCheck} --gotify";
                    Type = "oneshot";
                  };
                };

                "gotify-container-check@" = {
                  description = "Runs when service fails.";
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${lib.getExe gotifyAlert} %i";
                    EnvironmentFile = config.sops.templates."gotify-container-check.env".path;
                  };
                };
              };

              timers.container-version-check = {
                description = "Schedule docker version checks.";
                timerConfig = {
                  OnCalendar = "*-*-01/3 08:00:00";
                  Persistent = true;
                };
                wantedBy = [ "timers.target" ];
              };
            };

            sops = {
              secrets = {
                "gotify/URL" = { };
                "gotify/token/CONTAINERS" = { };
              };
              templates = {
                "gotify-container-check.env".content = ''
                  GOTIFY_URL=${config.sops.placeholder."gotify/URL"}
                  GOTIFY_APP_TOKEN=${config.sops.placeholder."gotify/token/CONTAINERS"}
                '';
              };
            };
          }
        )
      ];
    };
}
