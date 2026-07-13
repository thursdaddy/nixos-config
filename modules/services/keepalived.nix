_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.keepalived;
    in
    {
      options.mine.services.keepalived = {
        enable = lib.mkEnableOption "Enable Keepalived VRRP for High Availability";
        state = lib.mkOption {
          type = lib.types.enum [ "MASTER" "BACKUP" ];
          default = "BACKUP";
          description = "Initial VRRP state. MASTER will hold the IP initially.";
        };
        priority = lib.mkOption {
          type = lib.types.int;
          default = 100;
          description = "VRRP priority (higher wins the election).";
        };
        virtualIp = lib.mkOption {
          type = lib.types.str;
          description = "The Virtual IP to share (e.g., 192.168.10.53).";
        };
        interface = lib.mkOption {
          type = lib.types.str;
          default = "eth0";
          description = "The network interface to bind to (e.g. eno1, eth0).";
        };
        routerId = lib.mkOption {
          type = lib.types.int;
          default = 51;
          description = "VRRP Virtual Router ID (must be the same across all HA nodes).";
        };
      };

      config = lib.mkIf cfg.enable {
        # Allow VRRP protocol (IP protocol 112) through the firewall
        networking.firewall.extraCommands = ''
          iptables -I INPUT -p vrrp -j ACCEPT
        '';

        services.keepalived = {
          enable = true;
          vrrpScripts = {
            check_blocky = {
              script = "${pkgs.systemd}/bin/systemctl is-active --quiet blocky.service";
              interval = 2;
              weight = -60;
              user = "root";
            };
          };
          vrrpInstances = {
            "dns_ha" = {
              interface = cfg.interface;
              state = cfg.state;
              priority = cfg.priority;
              virtualRouterId = cfg.routerId;
              virtualIps = [
                { addr = cfg.virtualIp; }
              ];
              trackScripts = [ "check_blocky" ];
            };
          };
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              name = "keepalived";
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
