{ lib, inputs, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.services.upsnap;

in
{
  options.mine.services.upsnap = {
    enable = mkEnableOption "UpSnap WOL";
    packages = mkOpt types.package inputs.self.packages.${pkgs.system}.upSnap "Upsnap package.";
    listenAddress = mkOpt types.str "0.0.0.0" "Address on which to start webserver.";
    port = mkOpt types.port 8090 "Port of which to start webserver.";
    dataDir = mkOpt types.path "/opt/configs/upsnap" "Path for stored data.";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [
      inputs.self.packages.${pkgs.system}.upSnap
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # wip
    systemd.services.upsnap = {
      description = "Upsnap Wake-On-LAN utility";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      path = [ pkgs.samba ];
      environment = {
        XDG_CONFIG_HOME = "${cfg.dataDir}";
      };
      serviceConfig = {
        ExecStart = "${cfg.packages}/bin/upsnap serve --http ${cfg.listenAddress}:${builtins.toString cfg.port}  --dir ${cfg.dataDir}";
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        AmbientCapabilities = "CAP_NET_RAW";
        CapabilityBoundingSet = "CAP_NET_RAW";
      };
    };
  };
}
