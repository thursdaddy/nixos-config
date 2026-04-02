_: {
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

    in
    {
      options.mine.services.docker = {
        enable = lib.mkEnableOption "Enable Docker";
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
            docker_version_script = builtins.readFile ./scripts/container-version-check.py;
            docker_version_check = pkgs.writers.writePython3Bin "_container-version-check" {
              flakeIgnore = [
                "W503"
                "E501"
              ];
              libraries = with pkgs.python3Packages; [
                requests
                docker
              ];
            } docker_version_script;
          in
          lib.mkIf cfg.scripts.check-versions {
            environment.systemPackages = [
              docker_version_check
            ];

            systemd.services.container-version-check = {
              description = "container-version-check";
              serviceConfig = {
                Group = "docker";
                EnvironmentFile = config.sops.templates."gotify.env".path;
                ExecStart = "${docker_version_check}/bin/_container-version-check --gotify";
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
