_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "crowdsec";
      cfg = config.mine.containers.${name};
      hostName = config.networking.hostName;

      acquis_yaml = pkgs.writeText "acquis.yaml" ''
        source: loki
        url: http://192.168.10.68:3100/
        query: |
          {unit="podman-traefik.service"}
        labels:
          type: traefik
        ---
        source: loki
        url: http://192.168.10.68:3100/
        query: |
          {unit="podman-gitea.service"}
        labels:
          type: gitea
        ---
        source: loki
        url: http://192.168.10.68:3100/
        query: |
          {unit="podman-gotify.service"}
        labels:
          type: gotify
        ---
        source: loki
        url: http://192.168.10.68:3100/
        query: |
          {unit="podman-jellyfin.service"}
        labels:
          type: jellyfin
        ---
        source: loki
        url: http://192.168.10.68:3100/
        query: |
          {unit="podman-seerr.service"}
        labels:
          type: overseerr
      '';

      profiles_yaml = pkgs.writeText "profiles.yaml" ''
        name: default_ip_remediation
        filters:
         - Alert.Remediation == true && Alert.GetScope() == "Ip"
        decisions:
         - type: ban
           duration: 4h
        notifications:
          - gotify
        on_success: break
      '';

      gitea_logs_yaml = pkgs.writeText "gitea-logs.yaml" ''
        onsuccess: next_stage
        #debug: false
        name: LePresidente/gitea-logs
        filter: "evt.Parsed.program == 'gitea'"
        description: "Parse gitea logs"
        pattern_syntax:
          GITEA_CUSTOMUSER: "(%{EMAILADDRESS}|%{USERNAME})"
          GITEA_CUSTOMDATE: "%{DATE_X} %{TIME}"
        nodes:
          - grok:
              pattern: '^%{GITEA_CUSTOMDATE:timestamp}.*?Failed authentication attempt for %{GITEA_CUSTOMUSER:username} from %{IP:remote_ip}:%{NUMBER:remote_port}.* (user does not exist|Email address does not exist)'
              apply_on: message
              statics:
                - meta: log_type
                  value: gitea_failed_auth
          - grok:
              pattern: '^%{GITEA_CUSTOMDATE:timestamp}.*?Failed authentication attempt for %{GITEA_CUSTOMUSER:username} from \[%{IP:remote_ip}\].* (user does not exist|Email address does not exist)' 
              apply_on: message
              statics:
                - meta: log_type
                  value: gitea_failed_auth
          - grok:
              pattern: '^%{GITEA_CUSTOMDATE:timestamp}.*?Failed authentication attempt from %{IP:remote_ip}:%{NUMBER:remote_port}'
              apply_on: message
              statics:
                - meta: log_type
                  value: gitea_failed_auth
          - grok:
              pattern: '^%{GITEA_CUSTOMDATE:timestamp}.*?Failed authentication attempt from \[%{IP:remote_ip}\]'
              apply_on: message
              statics:
                - meta: log_type
                  value: gitea_failed_auth
          - grok:
              pattern: "^%{GITEA_CUSTOMDATE:timestamp}.*?Failed authentication attempt for %{GITEA_CUSTOMUSER:username} from %{IP:remote_ip}:%{NUMBER:remote_port}.* (user's password is invalid|User's password is invalid|password is invalid)"
              apply_on: message
              statics:
                - meta: log_type
                  value: gitea_failed_auth

        statics:
            - meta: service
              value: gitea
            - meta: user
              expression: "evt.Parsed.username"
            - target: evt.StrTime
              expression: evt.Parsed.timestamp
            - meta: source_ip
              expression: "evt.Parsed.remote_ip"
      '';
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik = {
              domain = config.nixos-thurs.publicDomain;
              static.${name} = {
                port = 8080;
                tailscale = true;
              };
            };
          };
        };

        networking.firewall.allowedTCPPorts = [ 8080 ];

        virtualisation.oci-containers.containers."${name}" = {
          image = "docker.io/crowdsecurity/crowdsec:v1.6.2";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          hostname = name;
          extraOptions = [
            "--network=host"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/${name}/config:/etc/crowdsec"
            "${config.mine.containers.settings.configPath}/${name}/data:/var/lib/crowdsec/data"
            "${acquis_yaml}:/etc/crowdsec/acquis.yaml"
            "${profiles_yaml}:/etc/crowdsec/profiles.yaml"
            "${gitea_logs_yaml}:/etc/crowdsec/parsers/s01-parse/gitea-logs.yaml"
            "/run/secrets/rendered/crowdsec-gotify.yaml:/etc/crowdsec/notifications/http.yaml:ro"
          ];
          environment = {
            TZ = config.time.timeZone;
            PUID = "1000";
            PGID = "100";
            COLLECTIONS = "crowdsecurity/traefik crowdsecurity/sshd LePresidente/gitea LePresidente/jellyfin baudneo/gotify LePresidente/overseerr crowdsecurity/whitelist-good-actors";
            DISABLE_ONLINE_API = "true";
          };
          labels = {
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}";
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs name;
            };
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
            services."${config.virtualisation.oci-containers.backend}-${name}".restartTriggers = [
              config.sops.templates."crowdsec-gotify.yaml".file
            ];
          };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
            "${alloyJournalBackup.name}" = alloyJournalBackup.value;
          };

        sops = {
          secrets = {
            "gotify/token/CROWDSEC" = { };
            "gotify/URL" = { };
          };
          templates."crowdsec-gotify.yaml" = {
            owner = "thurs";
            group = "users";
            content = ''
              type: http
              name: gotify
              log_level: info
              format: |
                {{ range . -}}
                {{ $alert := . -}}
                {
                  "extras": {
                    "client::display": {
                      "contentType": "text/markdown"
                    }
                  },
                  "priority": 0,
                  {{range .Decisions -}}
                  "title": "{{.Type }} {{ .Value }} for {{.Duration}}",
                  "message": "{{$alert.Scenario}} \n\n[crowdsec cti](https://app.crowdsec.net/cti/{{.Value -}}) \n\n[shodan](https://shodan.io/host/{{.Value -}})"
                  {{end -}}
                }
                {{ end -}}
              url: ${config.sops.placeholder."gotify/URL"}/message
              method: POST
              headers:
                X-Gotify-Key: ${config.sops.placeholder."gotify/token/CROWDSEC"}
                Content-Type: application/json
            '';
          };
        };
      };
    };
}
