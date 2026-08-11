_: {
  flake.modules.nixos.services =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      name = "gitea-runner";
      cfg = config.mine.services.${name};

      ociBackend =
        if config.mine.containers.settings.backend == "podman" then
          "podman"
        else if config.mine.containers.settings.backend == "docker" then
          "docker"
        else
          "";

      disableDnsFlag = if ociBackend == "podman" then " --disable-dns" else "";
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkEnableOption "Enable ${name}";
        runners = lib.mkOption {
          description = "gitea-runners";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  labels = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "labels for runner";
                  };
                  settings = lib.mkOption {
                    type = lib.types.attrs;
                    default = { };
                    description = "raw attr set for runner settings";
                  };
                };
              }
            )
          );
        };
      };

      config = lib.mkIf cfg.enable {
        services = {
          gitea-actions-runner = {
            instances = lib.mapAttrs (runnerName: runnerConfig: {
              name = runnerName;
              enable = true;
              url = "https://gitea.thurs.pw";
              tokenFile = config.sops.templates."gitea-runner.token".path;
              labels =
                [ ]
                ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
                  "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
                  "thurs-act:docker://gitea.thurs.pw/docker/ubuntu-act:latest"
                  "nix-runner:docker://gitea.thurs.pw/docker/nix-runner:latest"
                ]
                ++ runnerConfig.labels;
              inherit (runnerConfig) settings;
            }) cfg.runners;
          };
        };

        systemd.services = lib.mkMerge [
          {
            "init-${ociBackend}-gitea-runner-net" = {
              description = "Create ${ociBackend} network gitea-runner-net";
              wantedBy = [ "multi-user.target" ];
              before = map (runnerName: "gitea-runner-${runnerName}.service") (lib.attrNames cfg.runners);
              serviceConfig = {
                Type = "oneshot";
                ExecStart = [
                  "${pkgs.bash}/bin/bash -c '${lib.getExe pkgs.${ociBackend}} network inspect gitea-runner-net >/dev/null 2>&1 || ${lib.getExe pkgs.${ociBackend}} network create${disableDnsFlag} gitea-runner-net'"
                ];
              };
            };
          }
          (lib.mapAttrs' (runnerName: runnerConfig:
            lib.nameValuePair "gitea-runner-${runnerName}" {
              wants = [ "init-${ociBackend}-gitea-runner-net.service" ];
              after = [ "init-${ociBackend}-gitea-runner-net.service" ];
              serviceConfig.ExecStartPre = [
                "${pkgs.bash}/bin/bash -c '${lib.getExe pkgs.${ociBackend}} network inspect gitea-runner-net >/dev/null 2>&1 || ${lib.getExe pkgs.${ociBackend}} network create${disableDnsFlag} gitea-runner-net'"
              ];
            }
          ) cfg.runners)
        ];

        environment.etc = lib.mapAttrs' (runnerName: runnerConfig:
          lib.thurs.mkAlloyJournal {
            name = "gitea-runner-${runnerName}";
            serviceName = "gitea-runner-${runnerName}";
          }
        ) cfg.runners;

        sops = {
          secrets."gitea/RUNNER_TOKEN" = { };
          templates."gitea-runner.token".content = ''
            TOKEN=${config.sops.placeholder."gitea/RUNNER_TOKEN"}
          '';
        };
      };
    };
}
