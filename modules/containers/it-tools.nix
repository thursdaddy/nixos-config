_: {
  flake.modules.nixos.containers =
    { config, lib, ... }:
    let
      name = "it-tools";
      cfg = config.mine.containers.${name};
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "IT-Tools web utility collection";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            subDomain = "tools";
            port = 80;
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "ghcr.io/corentinth/it-tools:latest";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
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
