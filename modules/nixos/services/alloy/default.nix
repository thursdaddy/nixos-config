{ lib, config, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf mkForce;
  cfg = config.mine.services.alloy;
  alloy_config = ./${config.networking.hostName}-config.alloy;
in
{
  options.mine.services.alloy = {
    enable = mkEnableOption "Grafana Loki";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 12346 ];

    environment.etc."alloy/config.alloy" = {
      text = builtins.readFile alloy_config;
    };

    services.alloy = {
      enable = true;
      package = pkgs.unstable.grafana-alloy;
      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:12346"
        "--disable-reporting"
      ];
    };

    # users.groups.alloy = { };
    # users.users.alloy = {
    #   isSystemUser = true;
    #   uid = 473;
    #   group = "alloy";
    #   extraGroups = [ "thurs" "hass" "wheel" ];
    # };

    # permissions are wild
    systemd.services.alloy = {
      serviceConfig = {
        User = "root";
        Group = "root";
        DynamicUser = mkForce false;
      };
    };
  };
}
