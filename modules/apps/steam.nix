_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };

      systemd.user.services.steam = {
        description = "Steam Desktop Autostart";
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.steam}";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Slice = "app.slice";
        };
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "steam" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Steam.app" ];
  };
}
