{ inputs, ... }:
{
  flake.modules.nixos.blocky =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "blocky";
      port = 4000;
      cfg = config.mine.services.${name};

      # Check nixosConfigurations for "enabled" services and/or containers with a set
      # "subdomain" option. If found, uses subdomain value combined with
      # config.mine.*.traefik.rootDomainName and mapped to
      # config.mine.base.networking.meta.hostIp. These generate an attr set
      # used to in blockys customDNS.mapping entries.
      allConfigs = inputs.self.nixosConfigurations or { };

      includedHosts = [
        "cloudbox"
        "homebox"
        "jupiter"
        "kepler"
        "netpi1"
        "netpi2"
        "printpi"
      ];

      # Only crawl hosts that are in the list AND have a config defined
      targetHosts = lib.filterAttrs (
        name: v: (builtins.elem name includedHosts) && (v ? config)
      ) allConfigs;

      scrapeNixosConfigurations =
        hostName: hostValue:
        let
          mineCfg = hostValue.config.mine or { };

          serviceTraefikEnabled = mineCfg.services.traefik.enable or false;
          containerTraefikEnabled = mineCfg.containers.traefik.enable or false;
          traefikEnabled = serviceTraefikEnabled || containerTraefikEnabled;

          rootDomain =
            if serviceTraefikEnabled then
              mineCfg.services.traefik.rootDomainName or "thurs.pw"
            else
              mineCfg.containers.traefik.rootDomainName or "thurs.pw";

          hostIp = mineCfg.base.networking.meta.hostIp or "192.168.10.1";

          getMappings =
            attrs:
            let
              enabled = lib.filterAttrs (
                n: v: n != "settings" && (v.subdomain or null) != null && (v.enable or false)
              ) attrs;
            in
            lib.mapAttrs' (
              n: v:
              let
                sub = v.subdomain or n;
                fqdn = "${sub}.${rootDomain}";
              in
              lib.nameValuePair fqdn hostIp
            ) enabled;

        in
        if traefikEnabled then
          lib.recursiveUpdate (getMappings (mineCfg.containers or { })) (
            getMappings (mineCfg.services or { })
          )
        else
          { };

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
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "${name}-${config.mine.base.networking.hostName}";
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
                      "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/multi.txt"
                      "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
                      "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
                      "http://sysctl.org/cameleon/hosts"
                      "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
                    ];
                    special = [
                      "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
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
                  dns = 53;
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
                    "bazarr.thurs.pw" = "192.168.10.12";
                    "cloudbox.thurs.pw" = "100.71.122.112";
                    "deemix.thurs.pw" = "192.168.10.12";
                    "jellyfin.thurs.pw" = "192.168.10.189";
                    "lidarr.thurs.pw" = "192.168.10.12";
                    "plex.thurs.pw" = "192.168.10.189";
                    "radarr.thurs.pw" = "192.168.10.12";
                    "readarr.thurs.pw" = "192.168.10.12";
                    "sabnzbd.thurs.pw" = "192.168.10.12";
                    "sonarr.thurs.pw" = "192.168.10.12";
                    "tautulli.thurs.pw" = "192.168.10.189";
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
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
            traefik = lib.thurs.mkTraefikFile {
              inherit config;
              name = cfg.subdomain;
              inherit port;
            };
          in
          builtins.listToAttrs [
            alloyJournal
            traefik
          ];
      };
    };
}
