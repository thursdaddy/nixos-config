{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.alloy;
  alloy_config = ./${config.networking.hostName}-config.alloy;
in
{
  options.mine.services.alloy = {
    enable = mkEnableOption "Grafana Loki";
  };

  config = mkIf cfg.enable {
    environment.etc."alloy/config.alloy" = {
      text = builtins.readFile alloy_config;
    };
    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=127.0.0.1:12346"
        "--disable-reporting"
      ];
    };
  };
}
