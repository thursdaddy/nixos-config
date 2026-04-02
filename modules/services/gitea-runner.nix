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
        services.gitea-actions-runner = {
          instances = lib.mapAttrs (runnerName: runnerConfig: {
            name = runnerName;
            enable = true;
            url = "https://gitea.thurs.pw";
            tokenFile = config.sops.templates."gitea-runner.token".path;
            labels =
              [ ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
                "ubuntu-act:docker://catthehacker/ubuntu:act-latest"
                "thurs-act:docker://gitea.thurs.pw/docker/ubuntu-act:latest"
                "nix-runner:docker://gitea.thurs.pw/docker/nix-runner:latest"
              ]
              ++ runnerConfig.labels;
            inherit (runnerConfig) settings;
          }) cfg.runners;
        };

        sops = {
          secrets."gitea/RUNNER_TOKEN" = { };
          templates."gitea-runner.token".content = ''
            TOKEN=${config.sops.placeholder."gitea/RUNNER_TOKEN"}
          '';
        };
      };
    };
}
