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
              allVolumes = lib.flatten (lib.mapAttrsToList (n: c: c.volumes) config.virtualisation.oci-containers.containers);
              # Filter for volumes starting with our config path
              configVolumes = lib.filter (v: lib.hasPrefix "${cfg.configPath}/" v) allVolumes;
              # Extract host path (everything before the first colon)
              hostPaths = lib.map (v: builtins.head (lib.splitString ":" v)) configVolumes;
              uniquePaths = lib.unique hostPaths;
            in
            lib.map (path: "d ${path} 0755 ${user.name} users -") uniquePaths;
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
