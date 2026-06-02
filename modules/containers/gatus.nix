{ inputs, ... }:
{
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "gatus";
      version = "5.36.0";

      cfg = config.mine.containers.${name};

      gatus_config_yaml = pkgs.writeTextFile {
        name = "config.yaml";
        text = ''
          metrics: true
          storage:
            type: sqlite
            path: /data/history.db
          client:
            insecure: false
            ignore-redirect: false
            timeout: 10s
        '';
      };

      alloyJournal = lib.thurs.mkAlloyJournal {
        inherit name;
        serviceName = "${config.mine.containers.settings.backend}-${name}";
      };
    in
    {
      imports = [ inputs.nixos-thurs.nixosModules.gatus ];

      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        endpointsFile = lib.mkOption {
          description = "endpoints.yaml file";
          type = lib.types.path;
          default = config.nixos-thurs.gatus.publicEndpoints;
        };
        gotifyUrl = lib.mkOption {
          description = "server URL for gotify";
          type = lib.types.str;
          default = "http://gotify";
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              tailscale = true;
              port = 8080;
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "twinproduction/gatus:v${version}";
            pull = "always";
            hostname = "${name}";
            environment = {
              GATUS_CONFIG_PATH = "/config";
              GATUS_LOG_LEVEL = "WARN";
              TZ = config.time.timeZone;
            };
            volumes = [
              "${gatus_config_yaml}:/config/config.yaml"
              "${config.sops.templates."alerting.yaml".path}:/config/alerting.yaml"
              "${cfg.endpointsFile}:/config/endpoints.yaml"
              "${config.mine.containers.settings.configPath}/${name}:/data"
            ];
          };
        };

        sops = {
          secrets = {
            "discord/monitoring/WEBHOOK_URL" = { };
            "gotify/token/GATUS" = { };
            "gotify/URL" = { };
          };
          templates."alerting.yaml".content = ''
            alerting:
              custom:
                url: "${cfg.gotifyUrl}/message?token=${config.sops.placeholder."gotify/token/GATUS"}"
                method: "POST"
                headers:
                  Content-Type: "application/json"
                body: |
                  {
                    "message": "[RESULT_CONDITIONS]\n\n**URL:** [ENDPOINT_URL]\n\n**Group:** [ENDPOINT_GROUP]",
                    "extras": {
                      "client::display": {
                        "contentType": "text/markdown"
                      }
                    },
                    [ALERT_TRIGGERED_OR_RESOLVED] [ENDPOINT_URL]"
                  }
                placeholders:
                  ALERT_TRIGGERED_OR_RESOLVED:
                    TRIGGERED: '"priority": 8, "title": "‼️ DOWN:'
                    RESOLVED: '"priority": 4, "title": "✅ UP:'
              gotify:
                server-url: ${cfg.gotifyUrl}
                token: ${config.sops.placeholder."gotify/token/GATUS"}
                priority: 10
              discord:
                webhook-url: ${config.sops.placeholder."discord/monitoring/WEBHOOK_URL"}
                default:
                  enabled: true
                  failure-threshold: 2
                  success-threshold: 2
                  send-on-resolved: true
                  description: "healthcheck failed 2 times in a row"
          '';
        };

        environment.etc."${alloyJournal.name}" = alloyJournal.value;
      };
    };
}
