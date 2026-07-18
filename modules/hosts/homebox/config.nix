_: {
  configurations.nixos.homebox.module =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
      inherit (config.mine.base) user;
    in
    {
      mine = {
        base = {
          bluetooth = enabled;
          networking = {
            hostName = "homebox";
            wake-on-lan = {
              enable = true;
              interface = "eno1";
            };
          };
        };

        homelab.homebox = {
          hostIp = "192.168.10.60";
          tailscaleIp = "100.96.164.35";
          apps = {
            syncthing.traefik.static.syncthing.labels = {
              "traefik.http.routers.syncthing.middlewares" = "local-only";
            };
            hass.traefik.static.z2m.labels = {
              "traefik.http.routers.z2m.middlewares" = "local-only";
            };
            hass.traefik.static.esphome.labels = {
              "traefik.http.routers.esphome.middlewares" = "local-only";
            };
          };
        };
        services = {
          backups = enabled;
          celler = {
            enable = true;
            replication = {
              enable = true;
              role = "primary";
            };
            backupSync = {
              enable = true;
              targetHost = "streambox";
              interface = "eno1";
            };
          };
          keepalived = {
            enable = true;
            instances.celler = {
              state = "BACKUP";
              priority = 150;
              virtualIp = "192.168.10.54/24";
              interface = "eno1";
              routerId = 54;
              noPreempt = true;
              notifyMaster = ''
                /run/current-system/sw/bin/iptables -t nat -A PREROUTING -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -A PREROUTING -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:80 || true
                /run/current-system/sw/bin/iptables -t nat -A OUTPUT -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -A OUTPUT -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:80 || true
                /run/current-system/sw/bin/podman exec celler-db pg_ctl -D /var/lib/postgresql/data/pgdata promote || true
                systemctl start cellerd.service
              '';
              notifyBackup = ''
                systemctl stop cellerd.service
                /run/current-system/sw/bin/iptables -t nat -D PREROUTING -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -D PREROUTING -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:80 || true
                /run/current-system/sw/bin/iptables -t nat -D OUTPUT -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -D OUTPUT -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.homebox.hostIp}:80 || true
              '';
            };
          };
          victoriametrics = {
            enable = true;
            scrapeConfig = ''
              scrape_configs:
                - job_name: hass
                  scrape_interval: 60s
                  metrics_path: /api/prometheus
                  authorization:
                    credentials: "<SOPS:e7736e55519775257edab61c3f8621577e8c276104110e11be08886ddeb55c96:PLACEHOLDER>"
                  scheme: https
                  static_configs:
                    - targets: ["home.thurs.pw"]
            '';
          };
          gitea-runner = {
            enable = true;
            runners = {
              "${config.networking.hostName}" = {
                labels = [
                  "runner:docker://gitea.thurs.pw/docker/gitea-runner:v0.3.0"
                ];
                settings = {
                  runner = {
                    capacity = 4;
                  };
                };
              };
            };
          };
          sleep-on-lan = enabled;
          syncthing = {
            enable = true;
            folders = {
              "appd" = {
                path = "${user.homeDir}/appdaemon";
                devices = [
                  "mbp"
                  "c137"
                  "wormhole"
                ];
                ignorePerms = true;
              };
            };
          };
          traefik = {
            enable = true;
            dnsChallengeProvider = "gcp";
            extraCmds = [
              "--entrypoints.tailscale.address=:8443"
              "--entrypoints.websecure.address=192.168.10.60:443"
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
          };
        };
      };
      
      environment.etc."traefik/static/tesla-key.yaml".text = ''
        http:
          routers:
            tesla-key:
              rule: "Host(`homebox.fable-pinecone.ts.net`) && PathPrefix(`/.well-known/appspecific/com.tesla.3p.public-key.pem`)"
              service: "tesla-key"
              entryPoints:
                - "tailscale"
              middlewares:
                - "teslarewrite"
          middlewares:
            teslarewrite:
              replacePathRegex:
                regex: "^/.well-known/appspecific/com.tesla.3p.public-key.pem$"
                replacement: "/local/tesla/com.tesla.3p.public-key.pem"
          services:
            tesla-key:
              loadBalancer:
                servers:
                  - url: "http://127.0.0.1:8090"
      '';
      systemd.services.cellerd.wantedBy = lib.mkForce [ ];
    };
}
