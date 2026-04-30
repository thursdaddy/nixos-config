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
      cfg = config.mine.services.docker;
      gotifyAlert = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.gotify-alert;
    in
    {
      options.mine.services.docker = {
        enable = lib.mkEnableOption "Enable Docker";
        autoPrune = lib.mkOption {
          description = "Enable autoPrune";
          type = lib.types.bool;
          default = true;
        };
        scripts = lib.mkOption {
          default = { };
          description = "Docker related scripts";
          type = lib.types.submodule {
            options = {
              check-versions = lib.mkOption {
                description = "script to get current and latest container tags";
                type = lib.types.bool;
                default = true;
              };
            };
          };
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            virtualisation = {
              oci-containers.backend = "docker";
              docker = {
                enable = true;
                autoPrune = lib.mkIf cfg.autoPrune {
                  enable = true;
                  dates = "daily";
                  flags = [ "--all" ];
                };
              };
            };

            programs = lib.mkIf (user.shell.package == pkgs.fish) {
              fish = {
                shellAliases = config.mine.aliases.docker;
              };
            };

            users.users.${user.name}.extraGroups = [ "docker" ];
          }

          (
            let
              dockerVersionScript = builtins.readFile ./scripts/container-version-check.py;
              dockerVersionCheck = pkgs.writers.writePython3Bin "_container-version-check" {
                flakeIgnore = [
                  "W503"
                  "E501"
                ];
                libraries = with pkgs.python3Packages; [
                  requests
                  docker
                ];
              } dockerVersionScript;
            in
            lib.mkIf cfg.scripts.check-versions {
              environment.systemPackages = [
                dockerVersionCheck
              ];

              systemd = {
                services = {
                  container-version-check = {
                    description = "container-version-check";
                    onFailure = [ "gotify-container-check@%n.service" ];
                    serviceConfig = {
                      Group = "docker";
                      EnvironmentFile = config.sops.templates."gotify-container-check.env".path;
                      ExecStart = "${lib.getExe dockerVersionCheck} --gotify";
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
        ]
      );
    };
}
