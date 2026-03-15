_: {
  flake.modules.nixos.containers =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (config.mine.base) user;
      cfg = config.mine.containers;

    in
    {
      options.mine.containers = {
        settings = {
          configPath = lib.mkOption {
            description = "Base path for storing container configs";
            type = lib.types.path;
            default = "/opt/configs/";
          };
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

      config = lib.mkMerge [
        {
          virtualisation = {
            oci-containers.backend = "docker";
            docker = {
              enable = true;
              autoPrune = {
                enable = true;
                dates = "daily";
                flags = [ "--all" ];
              };
            };
          };

          users.users.${user.name}.extraGroups = [ "docker" ];
        }

        (
          let
            version_script = builtins.readFile ./scripts/container-version-check.py;
            version_check = pkgs.writers.writePython3Bin "_container-check" {
              flakeIgnore = [
                "W503"
                "E501"
              ];
              libraries = with pkgs.python3Packages; [
                requests
              ];
            } version_script;

            # wip
            refactor_version_script = builtins.readFile ./scripts/container-version-refactor.py;
            refactor_version_check = pkgs.writers.writePython3Bin "_container-check-refactor" {
              flakeIgnore = [
                "W503"
                "E501"
              ];
              libraries = with pkgs.python3Packages; [
                requests
                docker
              ];
            } refactor_version_script;
          in
          lib.mkIf cfg.scripts.check-versions {
            environment.systemPackages = [
              version_check
              refactor_version_check
            ];

            systemd.services.container-version-check = {
              description = "container-version-check";
              serviceConfig = {
                EnvironmentFile = config.sops.templates."gotify.env".path;
                ExecStart = "${refactor_version_check}/bin/_container-check-refactor --gotify";
                Type = "oneshot";
              };
            };

            sops = {
              secrets = {
                "gotify/URL" = { };
                "gotify/token/CONTAINERS" = { };
              };
              templates = {
                "gotify.env".content = ''
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
