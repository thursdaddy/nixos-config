_: {
  flake.modules.nixos.containers =
    { config, lib, ... }:
    let
      name = "syncthing";
      version = "2.0.16";

      cfg = config.mine.containers.${name};
      subdomain = "${name}-${config.networking.hostName}";
      fqdn = "${subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = lib.mkOption {
        default = { };
        description = "Configuration for the Syncthing container.";
        type = lib.types.submodule {
          options = {
            enable = lib.mkEnableOption "${name}";

            subdomain = lib.mkOption {
              type = lib.types.str;
              default = subdomain;
              description = "Subdomain for syncthing.";
            };

            volumePaths = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "List of paths for syncthing.";
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        networking.firewall = {
          allowedTCPPorts = [ 22000 ];
          allowedUDPPorts = [
            22000
            21027
          ];
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = " syncthing/syncthing:${version}";
          ports = [
            "8384"
            "0.0.0.0:22000:22000/tcp"
            "0.0.0.0:22000:22000/udp"
            "0.0.0.0:21027:21027/udp"
          ];
          environment = {
            PGID = "1000";
            PUID = "1000";
          };
          extraOptions = [
            "--network=traefik"
            "--pull=always"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/syncthing:/var/syncthing"
          ]
          ++ cfg.volumePaths;
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "8384";
          };
        };
      };
    };
}
