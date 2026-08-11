_: {
  configurations.nixos.streambox.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
    in
    {
      mine = {
        base.networking.hostName = "streambox";

        homelab.streambox = {
          hostIp = "192.168.10.189";
          tailscaleIp = "100.89.208.50";
        };

        containers = {
          settings.backend = "podman";
          audiobookshelf = enabled;
          immich = enabled;
          jellyfin = enabled;
          jellystat = enabled;
          navidrome = enabled;
          nextpvr = enabled;
          pinepods = enabled;
          seerr = enabled;
          tracearr = enabled;
          traefik = {
            enable = true;
            dashboard = true;
            dnsChallengeProvider = "gcp";
            enableCrowdsec = true;
            extraCmds = [
              "--accesslog=true"
              "--experimental.plugins.bouncer.modulename=github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
              "--experimental.plugins.bouncer.version=v1.6.0"
            ];
          };
        };

        services = {
          backups = enabled;
          celler = {
            enable = true;
            replication = {
              enable = true;
              role = "standby";
              primaryHost = "192.168.10.60";
            };
          };
          keepalived = {
            enable = true;
            vrrpScripts = {
              check_celler = {
                script = "${pkgs.postgresql}/bin/pg_isready -h 127.0.0.1 -p 54546";
                interval = 5;
                weight = -60;
                user = "root";
              };
            };
            instances.celler = {
              state = "BACKUP";
              priority = 100;
              virtualIp = "192.168.10.54/24";
              interface = "enp3s0";
              routerId = 54;
              noPreempt = true;
              trackScripts = [ "check_celler" ];
              notifyMaster = ''
                TARGET_IP="${config.mine.homelab.streambox.hostIp}"
                /run/current-system/sw/bin/iptables -t nat -A PREROUTING -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination $TARGET_IP:443 || true
                /run/current-system/sw/bin/iptables -t nat -A PREROUTING -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination $TARGET_IP:80 || true
                /run/current-system/sw/bin/iptables -t nat -A OUTPUT -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination $TARGET_IP:443 || true
                /run/current-system/sw/bin/iptables -t nat -A OUTPUT -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination $TARGET_IP:80 || true
                /run/current-system/sw/bin/podman exec -u postgres celler-db pg_ctl -D /var/lib/postgresql/data/pgdata promote || true
                systemctl start cellerd.service
              '';
              notifyBackup = ''
                systemctl stop cellerd.service
                TARGET_IP="${config.mine.homelab.streambox.hostIp}"
                /run/current-system/sw/bin/iptables -t nat -D PREROUTING -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination $TARGET_IP:443 || true
                /run/current-system/sw/bin/iptables -t nat -D PREROUTING -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination $TARGET_IP:80 || true
                /run/current-system/sw/bin/iptables -t nat -D OUTPUT -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination $TARGET_IP:443 || true
                /run/current-system/sw/bin/iptables -t nat -D OUTPUT -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination $TARGET_IP:80 || true
              '';
            };
          };
          ddns = enabled;
          mpd = enabled;
        };
      };

      services.resolved = {
        settings = {
          Resolve = {
            MulticastDNS = "no";
          };
        };
      };
      systemd.services.cellerd.wantedBy = lib.mkForce [ ];
    };
}
