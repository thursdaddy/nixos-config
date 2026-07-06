_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.gitlab-runner;

      runner_cfg_path = "/etc/gitlab-runner";
      runner_registration = pkgs.writers.writePython3Bin "_gitlab-runner" {
        doCheck = false;
        libraries = with pkgs.python3Packages; [
          requests
        ];
      } (builtins.readFile ./runner.py);
    in
    {
      options.mine.services.gitlab-runner = {
        enable = lib.mkEnableOption "gitlab-runner";
        url = lib.mkOption {
          description = "GitLab Instance URL";
          type = lib.types.str;
          default = "https://git.thurs.pw";
        };
        runners = lib.mkOption {
          description = "Gitlab-runners";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  tags = lib.mkOption {
                    type = lib.types.nullOr (lib.types.listOf lib.types.str);
                    default = null;
                    description = "list of tags for the runner";
                  };
                  dockerVolumes = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "volumes to attach to runner";
                  };
                  configFile = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Path to file containing CI_SERVER_URL and CI_SERVER_TOKEN. If provided, skips runner.py registration.";
                  };
                };
              }
            )
          );
        };
      };

      config = lib.mkIf cfg.enable {
        systemd = {
          services = {
            gitlab-runner = {
              requires = [
                "gitlab-runner-token.service"
              ];
            };

            gitlab-runner-token = {
              enable = true;
              description = "Manage Gitlab Runners";
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                Restart = "on-failure";
                RestartSec = "10s";
                RemainAfterExit = true;
                Environment = [
                  "GITLAB_URL=${cfg.url}"
                  "GITLAB_RUNNER_CONFIG_PATH=${runner_cfg_path}"
                ];
                EnvironmentFile = config.sops.templates."gitlab-runner.token".path;
              };
              script = ''
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    runnerName: runnerConfig:
                    if runnerConfig.configFile != null then
                      "echo 'Skipping dynamic registration for ${runnerName} (configFile provided)'"
                    else
                      let
                        tagList = lib.concatStringsSep "," runnerConfig.tags;
                      in
                      "/run/current-system/sw/bin/_gitlab-runner --register --name=${runnerName} --tags=${tagList}"
                  ) config.mine.services.gitlab-runner.runners
                )}
              '';
            };
          };
        };

        services.gitlab-runner = {
          enable = true;
          services = lib.mapAttrs (runnerName: runnerConfig: {
            description = "Gitlab Runner ${runnerName} on ${config.networking.hostName}.";
            requestConcurrency = 3;
            authenticationTokenConfigFile = if runnerConfig.configFile != null then runnerConfig.configFile else "${runner_cfg_path}/${runnerName}";
            executor = "docker";
            dockerImage = "alpine";
            dockerPullPolicy = "always";
            dockerPrivileged = true;
            inherit (runnerConfig) dockerVolumes;
            registrationFlags = [
              "--docker-network-mode=host"
            ];
          }) cfg.runners;
        };

        sops = {
          secrets."gitlab/ACCESS_TOKEN_RUNNER" = { };
          templates."gitlab-runner.token".content = ''
            GITLAB_ACCESS_TOKEN=${config.sops.placeholder."gitlab/ACCESS_TOKEN_RUNNER"}
          '';
        };

        systemd.tmpfiles.rules = [
          "d ${runner_cfg_path} 0755 root root - -"
        ];

        # Prevent gitlab-runner from auto-enabling docker if we're using podman
        virtualisation.docker.enable = lib.mkIf (config.mine.containers.settings.backend == "podman") (lib.mkForce false);

        environment.systemPackages = [
          runner_registration
        ];
      };
    };
}
