{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  inherit (lib.thurs) mkOpt;
  runnerSubmodule =
    { name, ... }:
    {
      options = {
        tags = mkOpt (types.nullOr (types.listOf types.str)) null "list of tags for the runner";
        dockerVolumes = mkOpt (types.listOf types.str) [ "" ] "volumes to attach to runner";
      };
    };

  cfg = config.mine.services.gitlab-runner;

  runner_cfg_path = "/etc/gitlab-runner";

  runner_script = builtins.readFile ./runner.py;
  runner_registration = pkgs.writers.writePython3Bin "_gitlab-runner" {
    flakeIgnore = [
      "E501"
      "E266"
      "E265"
      "E320"
    ];
    libraries = with pkgs.python3Packages; [
      requests
    ];
  } runner_script;

in
{
  options.mine.services.gitlab-runner = {
    enable = mkEnableOption "gitlab-runner";
    runners = mkOption {
      type = types.attrsOf (types.submodule runnerSubmodule);
      default = { };
      description = "Gitlab-runners";
    };
  };

  config = mkIf cfg.enable {
    sops = {
      secrets."gitlab/ACCESS_TOKEN_RUNNER" = { };
      templates."gitlab-runner.token".content = ''
        GITLAB_ACCESS_TOKEN=${config.sops.placeholder."gitlab/ACCESS_TOKEN_RUNNER"}
      '';
    };
    systemd.tmpfiles.rules = [
      "d ${runner_cfg_path} 0755 root root - -"
    ];

    environment.systemPackages = [
      runner_registration
    ];

    systemd = {
      services = {
        gitlab-runner = {
          bindsTo = [
            "gitlab-runner-token.service"
          ];
          after = [
            "gitlab-runner-token.service"
          ];
          partOf = [
            "gitlab-runner-token.service"
          ];
        };
        gitlab-runner-token = {
          enable = true;
          description = "Manage Gitlab Runners";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          requires = [ "network-online.target" ];
          requiredBy = [ "gitlab-runner.service" ];
          serviceConfig = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = "10s";
            RemainAfterExit = true;
            Environment = [
              "GITLAB_URL=https://git.thurs.pw"
              "GITLAB_RUNNER_CONFIG_PATH=${runner_cfg_path}"
            ];
            EnvironmentFile = config.sops.templates."gitlab-runner.token".path;
          };
          script = ''
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                runnerName: runnerConfig:
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
        authenticationTokenConfigFile = "${runner_cfg_path}/${runnerName}";
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
  };
}
