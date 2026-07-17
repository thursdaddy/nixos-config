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
      version = "0.10.2";

      cfg = config.mine.containers.${name};
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
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              subDomain = cfg.subdomain;
              port = 8080;
            };
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "ghcr.io/open-webui/open-webui:v${version}";
          ports = [
            "8080"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/open-webui:/app/backend/data"
          ];
          extraOptions = [
            "--add-host=host.docker.internal:host-gateway"
            "--pull=always"
          ];
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
