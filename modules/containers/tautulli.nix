_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "tautulli";
      version = "2.17.1";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            port = 8181;
            tailscale = true;
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "lscr.io/linuxserver/${name}:${version}";
            pull = "always";
            hostname = name;
            networks = [
              "plex"
            ];
            environment = {
              TZ = config.time.timeZone;
              PGID = "1000";
              PUID = "1000";
            };
            volumes = [
              "${configPath}/${name}:/config"
              "${configPath}/plex/Library/Application Support/Plex Media Server/Logs:/logs:ro"
            ];
            labels = {
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/TwiN/tautulli";
            };
          };
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
