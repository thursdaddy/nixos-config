_: {
  flake.modules.nixos.base =
    { config, lib, ... }:
    let
      globalConfig = config;
    in
    {
      config = {
        mine.homelabSharedModules = [
          (
            { name, ... }:
            {
              options.traefik = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  description = "Enable Traefik routing for this app. Auto-detects container/service state.";
                  default =
                    let
                      containerEnabled = globalConfig.mine.containers."${name}".enable or null;
                      serviceEnabled = globalConfig.mine.services."${name}".enable or null;
                    in
                    if containerEnabled != null then
                      containerEnabled
                    else if serviceEnabled != null then
                      serviceEnabled
                    else
                      true;
                };

                domain = lib.mkOption {
                  type = lib.types.str;
                  default =
                    globalConfig.mine.homelab.${globalConfig.networking.hostName}.rootDomainName or "thurs.pw";
                  description = "The root domain, used in traefik and blocky config";
                };

                isTraefikContainerEnabled = lib.mkOption {
                  description = "Is traefik container running";
                  type = lib.types.bool;
                  default = globalConfig.mine.containers.traefik.enable or false;
                };

                ociBackend = lib.mkOption {
                  type = lib.types.enum [
                    "docker"
                    "podman"
                    ""
                  ];
                  default = globalConfig.mine.containers.settings.backend or "";
                  description = "Container backend to run Traefik.";
                };

                static = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.submodule {
                      options = {
                        subDomain = lib.mkOption {
                          type = lib.types.str;
                          default = "";
                          description = "The subdomain, used in traefik and blocky config";
                        };
                        port = lib.mkOption { type = lib.types.int; };
                        ip = lib.mkOption {
                          type = lib.types.str;
                          default = "127.0.0.1";
                        };
                        tailscale = lib.mkOption {
                          type = lib.types.bool;
                          default = false;
                          description = "Attach via tailscale interface";
                        };
                        labels = lib.mkOption {
                          type = lib.types.attrsOf lib.types.anything;
                          default = { };
                          description = "Extra Traefik labels to apply (converted to TOML)";
                        };
                      };
                    }
                  );
                  default = { };
                };

                container = lib.mkOption {
                  type = lib.types.submodule {
                    options = {
                      subDomain = lib.mkOption {
                        type = lib.types.str;
                        default = "";
                        description = "The subdomain, used in traefik and blocky config";
                      };
                      port = lib.mkOption {
                        type = lib.types.nullOr lib.types.int;
                        default = null;
                        description = "Container port to route to. Setting this enables label generation.";
                      };
                      tailscale = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Attach via tailscale interface";
                      };
                    };
                  };
                  default = { };
                };
              };
            }
          )
        ];
      };
    };
}
