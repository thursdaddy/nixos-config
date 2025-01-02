{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.element;

in
{
  options.mine.apps.element = {
    enable = mkEnableOption "Element desktop client for Matrix";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      element-desktop
    ];

    systemd.user.services.element-desktop = {
      unitConfig = {
        Description = "A glossy Matrix collaboration client for the web. ";
        Documentation = "https://github.com/element-hq/element-web";
        PartOf = [ "hyprland-session.target" "desktop.service" ];
        After = [ "graphical-session.target" ];
      };

      serviceConfig = {
        ExecStart = "${pkgs.element-desktop}/bin/element-desktop";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        RestartSec = "2s";
        KillMode = "mixed";
      };

      wantedBy = [ "graphical-session.target" ];
    };
  };
}
