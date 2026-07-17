_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "nextpvr";
      version = "stable";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
      port = 8866;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.static.${name} = {
            subDomain = "nextpvr";
            inherit port;
            ip = config.mine.homelab.${config.networking.hostName}.hostIp;
            tailscale = true; # Route via Traefik over Tailscale!
          };
          nfs-mounts = {
            enable = true;
            mounts = {
              "/media/shows" = {
                device = "192.168.10.12:/media/shows";
              };
            };
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "docker.io/nextpvr/nextpvr_amd64:${version}";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          user = "1000:100"; # Run as user 'thurs' (1000) and group 'users' (100)
          volumes = [
            "${configPath}/${name}:/config"
            "/media/shows:/recordings"
            "${configPath}/${name}/buffer:/buffer"
          ];
          environment = {
            TZ = config.time.timeZone;
          };
          extraOptions = [
            "--network=host" # Run in host network mode to allow HDHomeRun discovery
          ];
          labels = {
            "enable.versions.check" = "false";
          };
        };

        networking.firewall.interfaces."podman+".allowedTCPPorts = [ 8866 ];
        networking.firewall.allowedUDPPorts = [
          1900  # SSDP/UPnP
          5004  # HDHomeRun video stream
          65001 # HDHomeRun discovery
        ];
        networking.firewall.extraCommands = ''
          iptables -A nixos-fw -s 192.168.10.228 -j ACCEPT
        '';

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
