_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        bitwarden-desktop
      ];

      systemd.user.services.bitwarden = {
        description = "Autostart service for Bitwarden";
        documentation = [ "https://bitwarden.com" ];
        enable = true;
        partOf = [ "apps.service" ];
        wantedBy = [ "apps.service" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.bitwarden-desktop}";
          ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          SuccessExitStatus = "1";
        };
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "bitwarden" ];
  };
}
