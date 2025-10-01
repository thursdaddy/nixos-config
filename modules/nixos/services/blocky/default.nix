{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.blocky;

in
{
  options.mine.services.blocky = {
    enable = mkEnableOption "Enable Blocky, a DNS proxy and ad-blocker for local network";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        53
        4000
      ];
      allowedUDPPorts = [ 53 ];
    };

    environment.systemPackages = [
      pkgs.blocky
    ];

    systemd.services.blocky = {
      description = "A DNS proxy and ad-blocker for the local network";
      wantedBy = [ "multi-user.target" ];
      reloadTriggers = [ config.environment.etc."blocky/config.yml".source or null ];

      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${lib.getExe pkgs.blocky} --config ${
          config.environment.etc."blocky/config.yml".source
        }";
        Restart = "on-failure";

        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      };
    };

    environment.etc = {
      "alloy/blocky.alloy" = mkIf config.mine.services.alloy.enable {
        text = builtins.readFile ./config.alloy;
      };
      "traefik/blocky.yml" = {
        text = builtins.readFile (
          pkgs.replaceVars ./traefik.yml {
            host = config.networking.hostName;
          }
        );
      };
      "blocky/config.yml" = {
        text = builtins.readFile ./blocky.yml;
      };
    };
  };
}
