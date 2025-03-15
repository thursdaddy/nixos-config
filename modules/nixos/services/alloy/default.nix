{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkForce;
  cfg = config.mine.services.alloy;
  alloy_base_conf = ./config.alloy;
in
{
  options.mine.services.alloy = {
    enable = mkEnableOption "Grafana Loki";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 12346 ];

    environment.etc."alloy/config.alloy" = {
      text = builtins.readFile alloy_base_conf;
    };

    services.alloy = {
      enable = true;
      package = pkgs.unstable.grafana-alloy;
      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:12346"
        "--disable-reporting"
      ];
    };

    systemd.services.alloy = {
      serviceConfig = {
        User = "root";
        Group = "root";
        DynamicUser = mkForce false;
      };
    };
  };
}
