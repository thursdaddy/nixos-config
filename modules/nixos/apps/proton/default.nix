{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.proton;

in
{
  options.mine.apps.proton = {
    enable = mkEnableOption "Enable Proton Apps";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unstable.protonvpn-gui
      unstable.protonvpn-cli
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
}
