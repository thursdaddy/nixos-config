_: {
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    {
      services.blueman.enable = true;

      systemd.user.services.blueman = {
        description = "Autostart service for Blueman Applet";
        requires = [ "tray.target" ];
        after = [
          "graphical-session.target"
          "tray.target"
        ];
        wantedBy = [
          "graphical-session.target"
        ];
        serviceConfig = {
          ExecStart = "${lib.getExe' pkgs.blueman "blueman-applet"}";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Slice = "app.slice";
        };
      };
    };
}
