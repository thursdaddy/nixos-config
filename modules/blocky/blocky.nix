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

      # Convert blocky.yml to JSON/attrSet
      blockyYAML = ./blocky.yml;
      yaml2json =
        file:
        let
          jsonOutputDrv = pkgs.runCommand "yaml-to-json" { } ''
            ${pkgs.yj}/bin/yj < "${file}" > $out
          '';
        in
        builtins.fromJSON (builtins.readFile jsonOutputDrv);
      blockyConfig = yaml2json blockyYAML;

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
      targetHosts = lib.filterAttrs (name: _: builtins.elem name includedHosts) allConfigs;
      scrapeNixosConfigurations =
        hostName: hostValue:
        let
          mine = hostValue.config.mine or { };

          serviceTraefik = mine.services.traefik or { };
          containerTraefik = mine.containers.traefik or { };

          traefikEnabled = (serviceTraefik.enable or false) || (containerTraefik.enable or false);

          rootDomain =
            if (serviceTraefik.enable or false) then
              serviceTraefik.rootDomainName
            else
              containerTraefik.rootDomainName or "thurs.pw";

          hostIp = mine.base.networking.meta.hostIp or "192.168.10.1";

          getMappings =
            attrs:
            let
              enabled = lib.filterAttrs (n: v: n != "settings" && (v.enable or false) && (v ? subdomain)) attrs;
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
          lib.recursiveUpdate (getMappings (mine.containers or { })) (getMappings (mine.services or { }))
        else
          { };

      scrapedCustomDnsMapping = lib.foldl' lib.recursiveUpdate { } (
        lib.mapAttrsToList scrapeNixosConfigurations targetHosts
      );

      # Manual DNS entries
      extraCustomDnsMapping = {
        "bazarr.thurs.pw" = "192.168.10.12";
        "radarr.thurs.pw" = "192.168.10.12";
        "readarr.thurs.pw" = "192.168.10.12";
        "sab.thurs.pw" = "192.168.10.12";
        "sabnzbd.thurs.pw" = "192.168.10.12";
        "sonarr.thurs.pw" = "192.168.10.12";
      };

      # Combine extraCustomDnsMapping and scrapedCustomDnsMapping into customDns.mapping
      finalCustomDnsMapping = {
        customDNS = {
          mapping = lib.recursiveUpdate scrapedCustomDnsMapping extraCustomDnsMapping;
        };
      };

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
        mine.base.networking =
          let
            inherit (lib.thurs) disabled enabled;
          in
          {
            ipv4Forwarding = enabled;
            resolved = disabled;
          };

        services.blocky = {
          enable = true;
          settings = lib.recursiveUpdate blockyConfig finalCustomDnsMapping;
        };

        networking.firewall = {
          allowedTCPPorts = [
            port
            53
            853
          ];
          allowedUDPPorts = [ 53 ];
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
