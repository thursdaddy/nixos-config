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
            wake-on-lan = {
              enable = true;
              interface = "ens19";
            };
          };
          utils.sysadmin = enabled;
        };

        homelab.wormhole = {
          hostIp = "192.168.10.51";
          tailscaleIp = "100.74.229.91";
        };

        containers = {
          settings.backend = "podman";
          traefik = {
            enable = true;
            dnsChallengeProvider = "gcp";
          };
          webdav.enable = true;
        };

        dev.tmux = {
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/dev/nix"
              "${user.homeDir}/dev/cloud"
              "${user.homeDir}/dev/homelab"
              "${user.homeDir}/notes"
            ];
          };
        };

        services = {
          gitlab-runner = {
            enable = true;
            url = "https://gitlab.com";
            runners = {
              "wormhole" = {
                configFile = config.sops.templates."gitlab-runner-wormhole".path;
                tags = [
                  "nix"
                  "builder"
                ];
                dockerVolumes = [ "/home/thurs/dev/nix/nixos-config/builds:/artifacts" ];
              };
            };
          };
          nginx = enabled;
          syncthing = {
            enable = true;
            folders = {
              "appd" = {
                path = "${user.homeDir}/appdaemon";
                devices = [
                  "mbp"
                  "c137"
                  "homebox"
                ];
                ignorePerms = true;
              };
              "dev-homelab" = {
                path = "${user.homeDir}/dev/homelab";
                devices = [
                  "mbp"
                  "c137"
                  "borrowbox"
                ];
                ignorePerms = true;
              };
              "dev-nix" = {
                path = "${user.homeDir}/dev/nix";
                devices = [
                  "mbp"
                  "c137"
                  "borrowbox"
                ];
                ignorePerms = true;
              };
              "dev-cloud" = {
                path = "${user.homeDir}/dev/cloud";
                devices = [
                  "mbp"
                  "c137"
                  "borrowbox"
                ];
                ignorePerms = true;
              };
              "notes" = {
                path = "${user.homeDir}/notes";
                devices = [
                  "mbp"
                  "pixel7-pro"
                  "c137"
                  "borrowbox"
                ];
                ignorePerms = true;
              };
            };
          };
          backups = enabled;
          gitea-runner = {
            enable = true;
            runners = {
              ${config.networking.hostName} = {
                settings = {
                  runner = {
                    capacity = 10;
                  };
                  container = {
                    force_pull = true;
                  };
                };
              };
            };
          };
          qemu-guest = enabled;
        };
      };

      sops = {
        secrets."gitlab/GITLAB_COM_RUNNER_TOKEN" = { };
        templates."gitlab-runner-wormhole".content = ''
          CI_SERVER_URL=https://gitlab.com
          CI_SERVER_TOKEN=${config.sops.placeholder."gitlab/GITLAB_COM_RUNNER_TOKEN"}
        '';
      };
    };
}
