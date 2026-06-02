_: {
  flake.modules.nixos.containers =
    { config, lib, ... }:
    let
      name = "syncthing";
      version = "2.1.0";

      cfg = config.mine.containers.${name};
      subdomain = "syncthing-${config.networking.hostName}";
    in
    {
      options.mine.containers.${name} = lib.mkOption {
        default = { };
        description = "Configuration for the Syncthing container.";
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "${name}";
            volumePaths = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "List of paths for syncthing.";
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              subDomain = "${subdomain}.${config.mine.containers.traefik.rootDomainName}";
              port = 8384;
            };
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "syncthing/syncthing:${version}";
          pull = "always";
          ports = [
            "0.0.0.0:22000:22000/tcp"
            "0.0.0.0:22000:22000/udp"
            "0.0.0.0:21027:21027/udp"
          ];
          environment = {
            PGID = "1000";
            PUID = "1000";
            TZ = config.time.timeZone;
          };
          volumes = [
            "${config.mine.containers.settings.configPath}/syncthing:/var/syncthing"
          ]
          ++ cfg.volumePaths;
        };

        networking.firewall = {
          allowedTCPPorts = [ 22000 ];
          allowedUDPPorts = [
            22000
            21027
          ];
        };
      };
    };
}
