_: {
  flake.modules.nixos.desktop =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      config = {
        systemd.user.services.syncthing-tray = {
          description = "autostart service for syncthing tray";
          documentation = [ "https://github.com/Martchus/syncthingtray" ];
          after = [ "graphical-session.target" ];
          bindsTo = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.syncthingtray-minimal}/bin/syncthingtray --wait";
            Restart = "always";
            KillMode = "mixed";
            Slice = "session.slice";
          };
        };
      };
    };
}
