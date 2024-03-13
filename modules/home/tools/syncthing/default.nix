{ lib, config, ... }:
with lib;
let

cfg = config.mine.home.syncthing;
user = config.mine.nixos.user;

in {
  options.mine.home.syncthing = {
    enable = mkEnableOption "Enable Syncthing";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 8384 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];

    home-manager.users.${user.name} = {
      services.syncthing = {
        enable = true;

        tray = {
          enable = true;
        };

      };
    };
  };

}
