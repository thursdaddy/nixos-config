{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.bitwarden;

in
{
  options.mine.apps.bitwarden = {
    enable = mkEnableOption "Install Bitwarden desktop app";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bitwarden
    ];

    systemd.user.services.bitwarden = {
      description = "Autostart service for Bitwarden";
      documentation = [ "https://bitwarden.com" ];
      enable = true;
      partOf = [ "desktop.service" ];
      wantedBy = [ "desktop.service" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.bitwarden}";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
        Restart = "on-failure";
        RestartSec = "5s";
        KillMode = "mixed";
        SuccessExitStatus = "1";
      };
    };
  };
}
