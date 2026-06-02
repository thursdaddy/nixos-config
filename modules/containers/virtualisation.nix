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
