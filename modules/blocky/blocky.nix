{ inputs, ... }:
{
  flake.modules.nixos.blocky =
    {
      config,
      lib,
      ...
    }:
    let
      name = "blocky";
      port = 4000;

      allConfigs = inputs.self.nixosConfigurations or { };

      includedHosts = [
        "c137"
        "homebox"
        "jupiter"
        "kepler"
        "netpi1"
        "netpi2"
        "printpi"
        "streambox"
        "wormhole"
        "gcloudbox"
        "cloudbox"
      ];

      targetHosts = lib.filterAttrs (
        hostName: v: (builtins.elem hostName includedHosts) && (v ? config)
      ) allConfigs;

      scrapeNixosConfigurations =
        hostName: hostValue:
        let
          mineCfg = hostValue.config.mine or { };
          hostData = mineCfg.homelab.${hostName} or { };
          rootDomain = hostData.rootDomainName or "thurs.pw";
          hostIp = hostData.hostIp or "192.168.0.0";
          tsIp = hostData.tailscaleIp or "100.100.0.0";

          homelabApps = hostData.apps or { };

        in
        lib.foldl' lib.recursiveUpdate { } (
          lib.mapAttrsToList (
            appName: appConfig:
            let
              domain =
                if (appConfig.traefik.domain or "") != "" && (appConfig.traefik.domain or "") != rootDomain then
                  appConfig.traefik.domain
                else
                  rootDomain;

              # 1. Map Static Routes
              staticRoutes = lib.filterAttrs (n: v: v.dns or true) (appConfig.traefik.static or { });
              staticMap = lib.mapAttrs' (
                routeName: routeConfig:
                let
                  sub = if (routeConfig.subDomain or "") != "" then routeConfig.subDomain else routeName;
                  fqdn = "${sub}.${domain}";
                  isTailscale = routeConfig.tailscale or false;
                  targetIp = if isTailscale then tsIp else hostIp;
                in
                lib.nameValuePair fqdn targetIp
              ) staticRoutes;

              # 2. Map Container Routes
              c = appConfig.traefik.container or { };
              containerMap =
                if ((c.port or null) != null || (c.tailscale or false) || (c.subDomain or "") != "") && (c.dns or true) then
                  let
                    sub = if (c.subDomain or "") != "" then c.subDomain else appName;
                    fqdn = "${sub}.${domain}";
                    isTailscale = c.tailscale or false;
                    targetIp = if isTailscale then tsIp else hostIp;
                  in
                  {
                    "${fqdn}" = targetIp;
                  }
                else
                  { };

            in
            lib.recursiveUpdate staticMap containerMap
          ) homelabApps
        );

      scrapedCustomDnsMapping = lib.foldl' lib.recursiveUpdate { } (
        lib.mapAttrsToList scrapeNixosConfigurations targetHosts
      );

    in
    {
      options.mine.services.${name} = {
        enable = lib.mkOption {
          description = "Enable Blocky";
          type = lib.types.bool;
          default = true;
        };
      };

      config = {
        services.blocky = {
          enable = true;
          settings =
            lib.recursiveUpdate
              {
                customDNS = {
                  mapping = scrapedCustomDnsMapping;
                };
              }
              {
                upstreams = {
                  init = {
                    strategy = "fast";
                  };
                  groups = {
                    default = [
                      "https://cloudflare-dns.com/dns-query"
                      "https://dns.quad9.net/dns-query"
                    ];
                  };
                };

                connectIPVersion = "dual";

                bootstrapDns = [
                  "tcp+udp:1.1.1.1"
                  "https://1.1.1.1/dns-query"
                ];

                blocking = {
                  denylists = {
                    ads = [
                      "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.txt"
                    ];
                    special = [
                      "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/tif.txt"
                    ];
                  };
                  clientGroupsBlock = {
                    default = [
                      "ads"
                      "special"
                    ];
                  };
                  blockType = "zeroIp";
                  blockTTL = "1m";
                  loading = {
                    refreshPeriod = "24h";
                  };
                };

                caching = {
                  minTime = "5m";
                  maxTime = "30m";
                };

                clientLookup = {
                  upstream = "192.168.20.1";
                  singleNameOrder = [
                    2
                    1
                  ];
                };

                ports = {
                  dns = [
                    "${config.mine.homelab.${config.networking.hostName}.hostIp}:53"
                    "${config.mine.homelab.${config.networking.hostName}.tailscaleIp}:53"
                    "192.168.10.53:53"
                  ];
                  http = 4000;
                  tls = 853;
                };

                prometheus = {
                  enable = true;
                  path = "/metrics";
                };

                log = {
                  level = "info";
                  format = "text";
                  timestamp = true;
                  privacy = false;
                };

                conditional = {
                  mapping = {
                    "thurs.pw" = "192.168.20.1";
                  };
                };

                customDNS = {
                  customTTL = "1h";
                  filterUnmappedTypes = true;
                  mapping = {
                    "attic.thurs.pw" = "192.168.10.60";
                    "jellyfin.${config.nixos-thurs.publicDomain}" = "192.168.10.189";
                    "mpd.thurs.pw" = allConfigs.streambox.config.mine.homelab.streambox.tailscaleIp;
                    "gcloudbox" = allConfigs.gcloudbox.config.mine.homelab.gcloudbox.tailscaleIp;
                    "gcloudbox.thurs.pw" = allConfigs.gcloudbox.config.mine.homelab.gcloudbox.tailscaleIp;
                    "cloudbox" = allConfigs.cloudbox.config.mine.homelab.cloudbox.tailscaleIp;
                    "cloudbox.thurs.pw" = allConfigs.cloudbox.config.mine.homelab.cloudbox.tailscaleIp;

                    "bazarr.thurs.pw" = "192.168.10.12";
                    "deemix.thurs.pw" = "192.168.10.12";
                    "lidarr.thurs.pw" = "192.168.10.12";
                    "radarr.thurs.pw" = "192.168.10.12";
                    "readarr.thurs.pw" = "192.168.10.12";
                    "sabnzbd.thurs.pw" = "192.168.10.12";
                    "sonarr.thurs.pw" = "192.168.10.12";
                    "sync-borrowbox.thurs.pw" = "192.168.10.12";
                  };
                };
              };
        };

        networking.firewall = {
          allowedTCPPorts = [
            port
            53
            853
          ];
          allowedUDPPorts = [ 53 ];
        };

        services.resolved.enable = false;

        boot.kernel.sysctl = {
          "net.ipv4.conf.all.forwarding" = true;
          "net.ipv4.ip_nonlocal_bind" = 1;
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
