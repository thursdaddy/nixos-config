_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;
      cfg = config.mine.containers.settings;
    in
    {
      options.mine.containers = {
        settings = {
          backend = lib.mkOption {
            description = "Backend docker or podman";
            type = lib.types.str;
            default = "podman";
          };
          autoPrune = lib.mkOption {
            description = "Enable autoPrune";
            type = lib.types.bool;
            default = true;
          };
          configPath = lib.mkOption {
            description = "Base path for storing container configs";
            type = lib.types.path;
            default = "/opt/configs";
          };
        };
      };

      config = lib.mkMerge [
        {
          programs = lib.mkIf (user.shell.package == pkgs.fish) {
            fish = {
              shellAliases = config.mine.aliases.docker;
            };
          };
          users.users.${user.name}.extraGroups = [ cfg.backend ];

          # Safely parse actual volume mounts to ensure we only create directories that are actively used
          systemd.tmpfiles.rules =
            let
              # Map each container definition to its volume rules with dynamic user/group ownership
              containerRules = lib.mapAttrsToList (name: container:
                let
                  # Check if PUID and PGID are defined in container environment, otherwise default to host user/users
                  puid = if container ? environment && container.environment ? PUID then container.environment.PUID else user.name;
                  pgid = if container ? environment && container.environment ? PGID then container.environment.PGID else "users";

                  # Find volume host paths starting with configPath
                  configVolumes = lib.filter (v: lib.hasPrefix "${cfg.configPath}/" v) container.volumes;
                  hostPaths = lib.map (v: builtins.head (lib.splitString ":" v)) configVolumes;
                in
                lib.map (path: "d ${path} 0755 ${puid} ${pgid} -") hostPaths
              ) config.virtualisation.oci-containers.containers;
            in
            lib.unique (lib.flatten containerRules);
        }
        {
          virtualisation.docker = lib.mkIf (cfg.backend == "docker") {
            enable = true;
            autoPrune = lib.mkIf cfg.autoPrune {
              enable = true;
              dates = "daily";
              flags = [ "--all" ];
            };
          };
        }
        {
          virtualisation.podman = lib.mkIf (cfg.backend == "podman") {
            enable = true;
            autoPrune = lib.mkIf cfg.autoPrune {
              enable = true;
              dates = "daily";
              flags = [ "--all" ];
            };
            defaultNetwork.settings.dns_enabled = true;
            dockerCompat = true;
            dockerSocket.enable = true;
          };

          boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

          networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];
        }
      ];
    };
}
