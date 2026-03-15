_: {
  flake.modules.nixos.services =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.mine.services.backups;
    in
    {
      options.mine.services.backups = {
        enable = lib.mkEnableOption "Enable my internal backup stuff";
      };

      config = lib.mkIf cfg.enable {
        mine = {
          base = {
            nfs-mounts = {
              enable = true;
              mounts = {
                "/backups" = {
                  device = "192.168.10.12:/fast/backups/${config.networking.hostName}";
                };
              };
            };
          };

          services = {
            gitlab-runner = {
              enable = true;
              runners = {
                backup = {
                  tags = [
                    "${config.networking.hostName}"
                    "backup"
                  ];
                  dockerVolumes = [
                    "/backups:/backups"
                    "/opt/configs:/opt/configs:ro"
                    "/var/lib:/fake/var/lib:ro"
                    "/var/run/docker.sock:/var/run/docker.sock"
                  ];
                };
              };
            };
          };
        };
      };
    };
}
