_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        unstable.proton-vpn
        protonmail-desktop
      ];

      systemd.user.services.protonmail = {
        description = "Protonmail Desktop Autostart";
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.protonmail-desktop}";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Slice = "app.slice";
        };
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [
      "protonvpn"
      "proton-mail"
    ];

    system.defaults.dock.persistent-apps = [ "/Applications/Proton Mail.app" ];
  };
}
