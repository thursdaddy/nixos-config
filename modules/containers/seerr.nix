_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      name = "seerr";
      version = "3.2.0";

      cfg = config.mine.containers.${name};
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              port = 5055;
              subDomain = "request";
            };
          };
        };
        virtualisation.oci-containers.containers."${name}" = {
          image = "${name}/${name}:v${version}";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = config.time.timeZone;
          };
          extraOptions = [
            "--dns=192.168.10.57"
            "--dns=192.168.10.201"
          ];
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
