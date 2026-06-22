_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "navidrome";
      version = "0.61.2";

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
            port = 4533;
            subDomain = "music";
            tailscale = true;
          };
          nfs-mounts = {
            enable = true;
            mounts = {
              "/mnt/music" = {
                device = "192.168.10.12:/fast/music";
              };
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "deluan/navidrome:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            volumes = [
              "/mnt/music:/music"
              "${configPath}/${name}/data:/data"
            ];
            environment = {
              ND_SCANNER_PURGEMISSING = "always";
            };
            labels = {
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/navidrome/navidrome";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${configPath}";
              "homelab.backup.retention.period" = "5";
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
