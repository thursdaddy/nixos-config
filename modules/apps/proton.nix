_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        unstable.protonvpn-gui
        protonmail-desktop
      ];

      systemd.user.services.protonmail = {
        description = "Autostart service for Protonmail Desktop";
        enable = true;
        partOf = [ "desktop.service" ];
        wantedBy = [ "desktop.service" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.protonmail-desktop}";
          ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          SuccessExitStatus = "1";
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
