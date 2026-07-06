_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.ddns;

      gotifyAlert = pkgs.gotify-alert;
      ddnsScript = pkgs.writers.writePython3Bin "ddns" {
        doCheck = false;
        libraries = with pkgs.python3Packages; [
          google-cloud-dns
          requests
        ];
      } (builtins.readFile ./ddns.py);
    in
    {
      options.mine.services.ddns = {
        enable = lib.mkEnableOption "Enable DDNS";
      };

      config = lib.mkIf cfg.enable {
        systemd = {
          services = {
            ddns = {
              description = "Dynamic DNS Updater";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              onFailure = [ "gotify-ddns-failure@%N.service" ];
              restartTriggers = [ config.sops.templates."ddns.env".file ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                EnvironmentFile = config.sops.templates."ddns.env".path;
                ExecStart = "${lib.getExe ddnsScript}";
                DynamicUser = true;
                LoadCredential = "CREDENTIALS.JSON:${config.sops.secrets."gcp/traefik/CREDENTIALS.JSON".path}";
              };
            };
            "gotify-ddns-failure@" = {
              description = "Runs when the ddns service fails.";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${lib.getExe gotifyAlert} %i";
                EnvironmentFile = config.sops.templates."ddns.env".path;
              };
            };
          };
          timers.ddns = {
            description = "Run DDNS Updater periodically";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "5min";
              OnUnitActiveSec = "1h";
              RandomizedDelaySec = "1min";
              Persistent = true;
            };
          };
        };

        sops = {
          secrets = {
            "ddns/DOMAINS" = { };
            "gcp/traefik/PROJECT_ID" = { };
            "gcp/traefik/CREDENTIALS.JSON" = { };
            "gotify/URL" = { };
            "gotify/token/DDNS" = { };
          };
          templates."ddns.env".content = ''
            DOMAINS=${config.sops.placeholder."ddns/DOMAINS"}
            GCP_PROJECT_ID=${config.sops.placeholder."gcp/traefik/PROJECT_ID"}
            GOTIFY_URL=${config.sops.placeholder."gotify/URL"}
            GOTIFY_APP_TOKEN=${config.sops.placeholder."gotify/token/DDNS"}
          '';
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              name = "ddns";
              serviceName = "ddns";
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
