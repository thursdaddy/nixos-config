{ lib, config, pkgs, inputs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.blocky;
  configFile = pkgs.writeTextFile {
    name = "blocky.yml";
    text = ''
      ${builtins.readFile ./blocky.yml}
      ${builtins.readFile config.nixos-thurs.blocky.customDnsMappings}
    '';
  };

in
{
  imports = [ inputs.nixos-thurs.nixosModules.blocky ];

  options.mine.services.blocky = {
    enable = mkEnableOption "Enable Ollama";
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
  };
}

