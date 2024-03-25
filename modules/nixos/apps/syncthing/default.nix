{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.syncthing;

in {
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 8384 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];

    systemd.user.services.syncthing-tray = {
      partOf = [ "desktop.service" ];
      description = "autostart service for syncthing tray";
      documentation = [ "https://github.com/Martchus/syncthingtray" ];
      enable = true;
      requires = [ "waybar.service" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.syncthingtray-minimal}/bin/syncthingtray --wait";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGUSR3 $MAINPID";
        Restart = "always";
        KillMode = "mixed";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      };
    };
  };
}
