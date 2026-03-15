_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        bitwarden-desktop
      ];

      systemd.user.services.bitwarden = {
        description = "Autostart service for Bitwarden";
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.bitwarden-desktop}";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Slice = "app.slice";
        };
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "bitwarden" ];
  };
}
