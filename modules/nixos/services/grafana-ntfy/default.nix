{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.grafana-ntfy;
in
{
  options.mine.services.grafana-ntfy = {
    enable = mkEnableOption "grafana-ntfy";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets."grafana-ntfy/USER" = { };
      secrets."grafana-ntfy/PASSWORD" = { };
      secrets."grafana-ntfy/TOPIC_URL" = { };
      templates."grafana-ntfy" = {
        content = ''
          NTFY_USER=${config.sops.placeholder."grafana-ntfy/USER"}
          NTFY_PASSWORD=${config.sops.placeholder."grafana-ntfy/PASSWORD"}
          NTFY_TOPIC_URL=${config.sops.placeholder."grafana-ntfy/TOPIC_URL"}
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 8888 ];

    systemd.services.grafana-ntfy = {
      enable = true;
      description = "Grafana notifications forwarder for ntfy.sh";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 5;
        EnvironmentFile = config.sops.templates."grafana-ntfy".path;
        ExecStart = "${
          inputs.self.packages.${pkgs.system}.grafana-ntfy
        }/bin/grafana-ntfy -ntfy-url $NTFY_TOPIC_URL -port 8888 -addr \":8888\" -username $NTFY_USER -password \"$NTFY_PASSWORD\" -debug";
        DynamicUser = true;
        UMask = "077";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        CapabilityBoundingSet = null;
      };
    };

    environment.etc = {
      "alloy/grafana-ntfy.alloy" = mkIf config.mine.services.alloy.enable {
        text = builtins.readFile ./config.alloy;
      };
    };
  };
}
