_: {
  configurations.nixos.wormhole.module =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
      inherit (config.mine.base) user;
    in
    {
      mine = {
        base = {
          nix.ghToken = enabled;
          networking = {
            hostName = "wormhole";
            meta = {
              hostIp = "192.168.10.51";
            };
            wake-on-lan = {
              enable = true;
              interface = "ens19";
            };
          };
          utils.sysadmin = enabled;
        };

        containers = {
          traefik = enabled;
          syncthing = {
            enable = true;
            volumePaths = [
              "${user.homeDir}/projects:/projects"
              "${user.homeDir}/documents/notes/:/notes"
            ];
          };
        };

        dev.tmux = {
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/projects/nix"
              "${user.homeDir}/projects/cloud"
              "${user.homeDir}/projects/homelab"
              "${user.homeDir}/projects/personal"
            ];
          };
        };

        services = {
          backups = enabled;
          gitlab-runner = {
            enable = true;
            runners = {
              docker = {
                tags = [
                  "${config.networking.hostName}"
                  "docker"
                ];
                dockerVolumes = [
                  "/var/run/docker.sock:/var/run/docker.sock"
                ];
              };
              gitlab = {
                tags = [
                  "builder"
                ];
                dockerVolumes = [
                  "/home/thurs/projects/nix/nixos-config/builds:/artifacts"
                ];
              };
            };
          };
          qemu-guest = enabled;
        };
      };

      # TODO: clean this up (need to add option for CI_SERVER_URL)
      sops = {
        secrets."gitlab/GITLAB_COM_RUNNER_TOKEN" = { };
        templates."gitlab-runner.token".content = ''
          CI_SERVER_URL=https://gitlab.com
          CI_SERVER_TOKEN=${config.sops.placeholder."gitlab/GITLAB_COM_RUNNER_TOKEN"}
        '';
      };

      services.gitlab-runner.services."gitlab".authenticationTokenConfigFile =
        lib.mkForce
          config.sops.templates."gitlab-runner.token".path;
    };
}
