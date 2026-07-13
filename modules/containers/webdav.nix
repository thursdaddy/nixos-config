_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "webdav";
      cfg = config.mine.containers.${name};
      port = 8080;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            subDomain = "notes";
            inherit port;
            tailscale = true; # Expose only over Tailscale!
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "docker.io/rclone/rclone:latest";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          user = "1000:1000"; # Run as user 'thurs'
          volumes = [
            "/home/thurs/notes/obsidian:/data"
          ];
          cmd = [
            "serve" "webdav" "/data"
            "--addr" ":8080"
          ];
          environment = {
            RCLONE_USER = "obsidian";
          };
          environmentFiles = [
            config.sops.templates."webdav.env".path
          ];
          labels = {
            "traefik.http.routers.${name}.entrypoints" = lib.mkForce "tailscale";
          };
        };

        sops = {
          secrets."webdav/PASSWORD" = { };
          templates."webdav.env".content = ''
            RCLONE_PASS=${config.sops.placeholder."webdav/PASSWORD"}
          '';
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
