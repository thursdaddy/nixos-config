_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "commafeed";
      version = "7.1.0";

      cfg = config.mine.containers.${name};
      port = 8082;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            subDomain = "feed";
            inherit port;
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "athou/commafeed:${version}-h2";
          pull = "always";
          networks = [ "traefik" ];
          volumes = [
            "${config.mine.containers.settings.configPath}/commafeed:/commafeed/data"
          ];
          labels = {
            "org.opencontainers.image.version" = "${version}";
            "org.opencontainers.image.source" = "https://github.com/Athou/commafeed";
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
