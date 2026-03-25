_: {
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # logiops
        solaar
      ];

      hardware = {
        logitech.wireless = {
          enable = true;
          enableGraphical = true;
        };
      };

      systemd.user.services.solaar-desktop = {
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.solaar} -w hide";
          Restart = "on-failure";
          RestartSec = "2s";
          KillMode = "mixed";
          Slice = "session.slice";
        };
      };
    };
}
