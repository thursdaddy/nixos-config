_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "open-webui";
      version = "0.8.5";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";

    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "ollama";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "ghcr.io/open-webui/open-webui:v${version}";
          ports = [
            "8080"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/open-webui:/app/backend/data"
          ];
          extraOptions = [
            "--network=traefik"
            "--add-host=host.docker.internal:host-gateway"
            "--pull=always"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.open-webui.tls" = "true";
            "traefik.http.routers.open-webui.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.open-webui.entrypoints" = "websecure";
            "traefik.http.routers.open-webui.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.open-webui.loadbalancer.server.port" = "8080";
          };
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "docker-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
