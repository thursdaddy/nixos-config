{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.blocky;

  configFile = pkgs.writeTextFile {
    name = "blocky.yml";
    text = builtins.readFile ./blocky.yml;
  };
in
{
  options.mine.services.blocky = {
    enable = mkEnableOption "Enable Blocky, a DNS proxy and ad-blocker for local network";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    environment.systemPackages = [
      pkgs.blocky
    ];

    systemd.services.blocky = {
      description = "A DNS proxy and ad-blocker for the local network";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${lib.getExe pkgs.blocky} --config ${configFile} ";
        Restart = "on-failure";

        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      };
    };

    environment.etc = mkIf config.mine.services.alloy.enable {
      "alloy/blocky.alloy" = {
        text = builtins.readFile ./config.alloy;
      };
    };
  };
}
