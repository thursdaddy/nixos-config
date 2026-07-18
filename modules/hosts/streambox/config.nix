_: {
  configurations.nixos.streambox.module =
    {
      config,
      lib,
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
            extraCmds = [
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
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
            instances.celler = {
              state = "BACKUP";
              priority = 100;
              virtualIp = "192.168.10.54/24";
              interface = "enp3s0";
              routerId = 54;
              noPreempt = true;
              notifyMaster = ''
                /run/current-system/sw/bin/iptables -t nat -A PREROUTING -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -A PREROUTING -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:80 || true
                /run/current-system/sw/bin/iptables -t nat -A OUTPUT -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -A OUTPUT -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:80 || true
                /run/current-system/sw/bin/podman exec celler-db pg_ctl -D /var/lib/postgresql/data/pgdata promote || true
                systemctl start cellerd.service
              '';
              notifyBackup = ''
                systemctl stop cellerd.service
                /run/current-system/sw/bin/iptables -t nat -D PREROUTING -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -D PREROUTING -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:80 || true
                /run/current-system/sw/bin/iptables -t nat -D OUTPUT -d 192.168.10.54 -p tcp --dport 443 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:443 || true
                /run/current-system/sw/bin/iptables -t nat -D OUTPUT -d 192.168.10.54 -p tcp --dport 80 -j DNAT --to-destination ${config.mine.homelab.streambox.hostIp}:80 || true
              '';
            };
          };
          ddns = enabled;
          mpd = enabled;
        };
      };

      services.resolved = {
        extraConfig = ''
          MulticastDNS=no
        '';
      };
      systemd.services.cellerd.wantedBy = lib.mkForce [ ];
    };
}
