{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.bitwarden;

in
{
  options.mine.desktop.bitwarden = {
    enable = mkEnableOption "Install Bitwarden desktop";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.bitwarden
    ];

    systemd.user.services.bitwarden = {
      description = "Autostart service for Bitwarden";
      documentation = [ "https://bitwarden.com" ];
      partOf = [ "desktop.service" ];
      enable = true;
      wants = [ "waybar.service" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.bitwarden}";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
        SuccessExitStatus = "1";
      };
    };
  };
}
