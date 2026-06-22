_: {
  flake.modules.nixos.containers =
    { config, lib, ... }:
    let
      name = "thelounge";
      version = "4.5.0";

      cfg = config.mine.containers.${name};
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "thelounge IRC client";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            subDomain = "irc";
            port = 9000;
          };
        };
        virtualisation.oci-containers.containers."${name}" = {
          image = "thelounge/thelounge:${version}";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          environment = {
            PUID = "1000";
            PGID = "1000";
          };
          volumes = [
            "${config.mine.containers.settings.configPath}/thelounge:/var/opt/thelounge"
          ];
        };
      };
    };
}
