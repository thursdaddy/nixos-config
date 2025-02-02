{ lib, pkgs, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.services.beszel;

in
{
  options.mine.services.beszel = {
    enable = mkEnableOption "Enable Beszel, a lightweight server monitoring platform";
    listenAddress = mkOpt types.str "0.0.0.0" "Address on which to start webserver.";
    dataDir = mkOpt types.path "/opt/configs/beszel-hub" "Path for stored data.";
    isHub = mkEnableOption "Run as Beszel Hub";
    hubPort = mkOpt types.port 8890 "Port of which to start webserver.";
    hubPubKey = mkOpt types.str "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACtKZg/D2PNYeYZfJ6jCCHtxaW12T7k/83xqwV8KJzC" "Hub Public Key";
    isAgent = mkEnableOption "Run as Beszel Agent";
    agentPort = mkOpt types.port 45876 "Port of which to start webserver.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unstable.beszel
    ];

    networking.firewall.allowedTCPPorts = [ (mkIf cfg.isHub cfg.hubPort) (mkIf cfg.isAgent cfg.agentPort) ];

    systemd.services.beszel-hub = mkIf cfg.isHub {
      description = "Beszel-Hub";
      enable = true;
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.unstable.beszel}/bin/beszel-hub serve --http ${cfg.listenAddress}:${builtins.toString cfg.hubPort}  --dir ${cfg.dataDir}";
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    systemd.services.beszel-agent = mkIf cfg.isAgent {
      description = "Beszel-Agent";
      enable = true;
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        PORT = "${builtins.toString cfg.agentPort}";
        KEY = "${cfg.hubPubKey}";
      };
      serviceConfig = {
        ExecStart = "${pkgs.unstable.beszel}/bin/beszel-agent";
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
