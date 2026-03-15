_: {
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.base.networking;
      inherit (config.mine.base) user;
    in
    {
      options.mine.base.networking = {
        hostName = lib.mkOption {
          description = "Hostname";
          type = lib.types.str;
          default = "localhost";
        };
        meta.hostIp = lib.mkOption {
          description = "Metadata used with blocky/traefik modules";
          type = lib.types.str;
          default = "100.100.100.100";
        };
        networkd.enable = lib.mkOption {
          description = "Enable systemd-networkd";
          type = lib.types.bool;
          default = true;
        };
        resolved.enable = lib.mkOption {
          description = "Enable systemd-resolved";
          type = lib.types.bool;
          default = cfg.networkd.enable;
        };
        networkManager.enable = lib.mkEnableOption "Enable NetworkManager";
        ipv4Forwarding.enable = lib.mkEnableOption "Enable ipv4 Forwarding";
        firewall.enable = lib.mkOption {
          description = "Enable Firewall";
          type = lib.types.bool;
          default = true;
        };
        wake-on-lan = lib.mkOption {
          default = { };
          description = "wake-on-lan";
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "Enable WOL";
              interface = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "Interface to enable WOL";
              };
            };
          };
        };
      };
      config = lib.mkMerge [
        {
          networking = {
            firewall.enable = cfg.firewall.enable;
            hostName = cfg.hostName;
            useDHCP = lib.mkDefault true;
            interfaces = lib.mkIf cfg.wake-on-lan.enable {
              "${cfg.wake-on-lan.interface}".wakeOnLan.enable = true;
            };
            useNetworkd = lib.mkIf cfg.networkd.enable true;
          };

          systemd.network.enable = lib.mkIf cfg.networkd.enable true;
          services.resolved.enable = lib.mkIf (!cfg.resolved.enable) false; # conflicts with blocky

          boot.kernel.sysctl = {
            "net.ipv4.conf.all.forwarding" = lib.mkIf cfg.ipv4Forwarding.enable true;
          };
        }

        # NetworkManager
        (lib.mkIf cfg.networkManager.enable {
          # disable networkd
          mine.base.networking.networkd.enable = false;

          networking.networkmanager = {
            enable = true;
            plugins = with pkgs; [
              networkmanager-openvpn
            ];
          };

          # programs.nm-applet.enable = true;
          environment.systemPackages = [
            pkgs.networkmanagerapplet
          ];

          users.users.${user.name}.extraGroups = [ "networkmanager" ];
        })
      ];
    };
}
