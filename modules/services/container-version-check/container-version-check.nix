_: {
  flake.modules.nixos.services =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.mine.services.container-version-check;
      gotifyAlert = pkgs.gotify-alert;
    in
    {
      options.mine.services.container-version-check = {
        enable = lib.mkOption {
          description = "Container-version-check";
          type = lib.types.bool;
          default = (config.virtualisation.docker.enable || config.virtualisation.podman.enable);
        };
      };

      config =
        let
          containerVersionScript = builtins.readFile ./container-version-check.py;
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
        lib.mkIf cfg.enable {
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
        };
    };
}
