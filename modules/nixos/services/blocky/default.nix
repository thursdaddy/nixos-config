{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.blocky;
  blockyYAML = ./blocky.yml;
  yaml2json =
    file:
    let
      jsonOutputDrv = pkgs.runCommand "yaml-to-json" { } ''
        ${pkgs.yj}/bin/yj < "${blockyYAML}" > $out
      '';
    in
    builtins.fromJSON (builtins.readFile jsonOutputDrv);
  blockyConfig = yaml2json blockyYAML;
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

    services.blocky = {
      enable = true;
      settings = blockyConfig;
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
    };
  };
}
