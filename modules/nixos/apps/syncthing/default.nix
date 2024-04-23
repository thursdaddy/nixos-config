{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.syncthing;

in
{
  options.mine.apps.syncthing = {
    isNix = mkEnableOption "Enable NixOS config for syncthing";
  };

  config = mkIf cfg.isNix {
    systemd.user.services.syncthing-tray = {
      description = "autostart service for syncthing tray";
      documentation = [ "https://github.com/Martchus/syncthingtray" ];
      enable = true;
      partOf = [ "desktop.service" ];
      wantedBy = [ "desktop.service" ];
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
        ExecStart = "${pkgs.syncthingtray-minimal}/bin/syncthingtray --wait";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGUSR3 $MAINPID";
        Restart = "always";
        KillMode = "mixed";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8384 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
