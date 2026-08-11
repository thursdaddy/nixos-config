_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      name = "seerr";
      version = "3.4.1";

      cfg = config.mine.containers.${name};
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik = {
              domain = config.nixos-thurs.publicDomain;
              container = {
                port = 5055;
                subDomain = "request";
              };
            };
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "${name}/${name}:v${version}";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          hostname = name;
          networks = [
            "jellyfin"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = config.time.timeZone;
            LOG_LEVEL = "info";
          };
          volumes = [
            "${config.mine.containers.settings.configPath}/${name}:/app/config"
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
