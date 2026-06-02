_: {
  flake.modules.nixos.base =
    { lib, config, ... }:
    {
      options.mine = {
        homelabSharedModules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [ ];
          internal = true;
        };

        homelab = lib.mkOption {
          description = "Per-host homelab configurations.";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                # HOST specific: config.mine.homelab.${config.networking.hostName}.
                hostIp = lib.mkOption {
                  description = "Metadata used with blocky/traefik modules";
                  type = lib.types.str;
                  default = "100.100.100.100";
                };
                tailscaleIp = lib.mkOption {
                  description = "Metadata used with container modules";
                  type = lib.types.str;
                  default = "100.100.100.100";
                };
                rootDomainName = lib.mkOption {
                  description = "Metadata used with traefik/blocky modules";
                  type = lib.types.str;
                  default = "thurs.pw";
                };

                services = lib.mkOption {
                  default = { };
                  description = "Homelab related scripts";
                  type = lib.types.submodule {
                    options = {
                      container-version-check = lib.mkOption {
                        type = lib.types.bool;
                        default = (config.virtualisation.docker.enable || config.virtualisation.podman.enable);
                      };
                      ddns = lib.mkEnableOption "DDNS";
                    };
                  };
                };

                # HOST specific: config.mine.homelab.${config.networking.hostName}.nfs-mounts
                nfs-mounts = {
                  enable = lib.mkEnableOption "NFS mounts";
                  mounts = lib.mkOption {
                    description = "NFS Mount configs";
                    default = { };
                    type = lib.types.attrsOf (
                      lib.types.submodule {
                        freeformType = lib.types.attrs;
                        options = {
                          device = lib.mkOption {
                            type = lib.types.nullOr lib.types.str;
                            default = null;
                            description = "NFS address and path";
                          };
                          fsType = lib.mkOption {
                            type = lib.types.str;
                            default = "nfs";
                            description = "fsType";
                          };
                          options = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [
                              "auto"
                              "_netdev"
                              "bg"
                              "timeo=30"
                              "retrans=2"
                              "x-systemd.mount-timeout=10"
                            ];
                            description = "Default mount options";
                          };
                        };
                      }
                    );
                  };
                };

                # HOST specific: config.mine.homelab.${config.networking.hostName}.apps
                # Used with Traefik/Alloy modules
                apps = lib.mkOption {
                  description = "Applications running on this host.";
                  default = { };
                  type = lib.types.lazyAttrsOf (
                    lib.types.submoduleWith {
                      modules = config.mine.homelabSharedModules ++ [
                        {
                          options.config = lib.mkOption {
                            type = lib.types.deferredModule;
                          };
                        }
                      ];
                    }
                  );
                };
              };
            }
          );
        };
      };
    };
}
