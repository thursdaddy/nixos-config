{ inputs, ... }:
{
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.homelab.${config.networking.hostName}.services.ddns;

      gotifyAlert = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.gotify-alert;
      ddnsScript = pkgs.writers.writePython3Bin "route53-ddns" {
        doCheck = false;
        libraries = with pkgs.python3Packages; [
          boto3
          requests
        ];
      } (builtins.readFile ./scripts/ddns.py);
    in
    {
      config = lib.mkIf cfg {
        systemd = {
          services = {
            route53-ddns = {
              description = "Route53 Dynamic DNS Updater";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              onFailure = [ "gotify-ddns-failure@%N.service" ];
              serviceConfig = {
                Type = "oneshot";
                EnvironmentFile = config.sops.templates."ddns.env".path;
                ExecStart = "${lib.getExe ddnsScript}";
                DynamicUser = true;
              };
            };
            "gotify-ddns-failure@" = {
              description = "Runs when the route53-ddn service fails.";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${lib.getExe gotifyAlert} %i";
                EnvironmentFile = config.sops.templates."ddns.env".path;
              };
            };
          };
          timers.route53-ddns = {
            description = "Run Route53 DDNS Updater periodically";
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
            "aws/traefik/AWS_ACCESS_KEY_ID" = { };
            "aws/traefik/AWS_SECRET_ACCESS_KEY" = { };
            "aws/traefik/AWS_HOSTED_ZONE_ID" = { };
            "gotify/URL" = { };
            "gotify/token/DDNS" = { };
          };
          templates."ddns.env".content = ''
            DOMAINS=${config.sops.placeholder."ddns/DOMAINS"}
            AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."aws/traefik/AWS_SECRET_ACCESS_KEY"}
            AWS_ACCESS_KEY_ID=${config.sops.placeholder."aws/traefik/AWS_ACCESS_KEY_ID"}
            AWS_DEFAULT_REGION="us-west-2"
            GOTIFY_URL=${config.sops.placeholder."gotify/URL"}
            GOTIFY_APP_TOKEN=${config.sops.placeholder."gotify/token/DDNS"}
          '';
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              name = "route53-ddns";
              serviceName = "route53-ddns";
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
