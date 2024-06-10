{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.mine.system.services.sleep-on-lan;
in
{
  options.mine.system.services.sleep-on-lan = {
    enable = mkEnableOption "Enable sleep-on-lan";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sleep-on-lan
    ];

    networking.firewall.allowedUDPPorts = [ 9 ];
    networking.firewall.allowedTCPPorts = [ 9 8009 ];

    systemd.services.sleep-on-lan = {
      enable = true;
      description = "Enable sleep-on-lan daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.sleep-on-lan}/bin/sleep-on-lan";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
        Restart = "always";
      };
    };
  };
}
