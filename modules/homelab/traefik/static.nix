_: {
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      globalConfig = config;
      hostName = config.networking.hostName;

      hostData = config.mine.homelab.${hostName} or { };
      cfg = hostData.apps or { };

      activeApps = lib.filterAttrs (
        name: appConfig:
        let
          containerEnabled = globalConfig.mine.containers.${name}.enable or false;
          serviceEnabled = globalConfig.mine.services.${name}.enable or false;
          isPureStaticProxy = (appConfig.traefik.container.port == null) && (appConfig.traefik.static != { });
        in
        containerEnabled || serviceEnabled || isPureStaticProxy
      ) cfg;

      containerFlags = lib.mapAttrsToList (
        name: homelabConfig: homelabConfig.traefik.isTraefikContainerEnabled
      ) activeApps;
      traefikContainerRunning = builtins.elem true containerFlags;

      getOciBackends = lib.unique (
        lib.mapAttrsToList (name: homelabConfig: homelabConfig.traefik.ociBackend) activeApps
      );
      ociBackend =
        if builtins.elem "docker" getOciBackends then
          "docker"
        else if builtins.elem "podman" getOciBackends then
          "podman"
        else
          "";

      parseLabels = labels:
        let
          labelList = lib.mapAttrsToList (key: val: { inherit key val; }) labels;
          traefikLabels = builtins.filter (x: lib.hasPrefix "traefik." x.key) labelList;
          toNested = { key, val }:
            let
              cleanKey = lib.removePrefix "traefik." key;
              path = lib.splitString "." cleanKey;
              lastPath = lib.last path;
              coercedVal =
                if val == "true" || val == true then true
                else if val == "false" || val == false then false
                else if builtins.elem lastPath [ "middlewares" "entrypoints" ] && builtins.isString val then lib.splitString "," val
                else if (builtins.isString val && builtins.match "[0-9]+" val != null && builtins.elem lastPath [ "port" "maxretry" "priority" "weight" ]) then builtins.fromJSON val
                else val;
            in
            lib.setAttrByPath path coercedVal;
        in
        lib.foldl' (acc: x: lib.recursiveUpdate acc (toNested x)) { } traefikLabels;

      staticRoutes = lib.flatten (
        lib.mapAttrsToList (
          name: homelabConfig:
          lib.mapAttrsToList (
            routeName: routeConfig:
            let
              subdomain =
                if homelabConfig.traefik.static.${routeName}.subDomain == "" then
                  routeName
                else
                  homelabConfig.traefik.static.${routeName}.subDomain;
              domain =
                if homelabConfig.traefik.domain != hostData.rootDomainName then
                  homelabConfig.traefik.domain
                else
                  hostData.rootDomainName;

              ip =
                if routeConfig.ip != "127.0.0.1" then
                  routeConfig.ip
                else if config.mine.services.traefik.enable or false then
                  "127.0.0.1"
                else if config.mine.containers.traefik.enable or false then
                  "host.docker.internal"
                else
                  "127.0.0.1";

              entryPoint =
                if homelabConfig.traefik.static.${routeName}.tailscale or false then "tailscale" else "websecure";
              identifier = "${routeName}";

              defaultConfig = {
                http = {
                  routers."${identifier}" = {
                    rule = "Host(`${subdomain}.${domain}`)";
                    service = identifier;
                    entryPoints = [ entryPoint ];
                    tls.certResolver = "letsencrypt";
                  };
                  services."${identifier}".loadBalancer.servers = [
                    { url = "http://${ip}:${builtins.toString routeConfig.port}"; }
                  ];
                };
              };

              routeConfigAttrs = lib.recursiveUpdate defaultConfig (parseLabels routeConfig.labels);

              configFile = pkgs.writeText "traefik-static-${identifier}.yaml" (lib.generators.toYAML {} routeConfigAttrs);
            in
            {
              inherit routeName configFile identifier;
            }
          ) homelabConfig.traefik.static
        ) activeApps
      );

    in
    {
      config = {
        environment.etc = builtins.listToAttrs (
          map (
            route: lib.nameValuePair "traefik/static/${route.identifier}.yaml" { source = route.configFile; }
          ) staticRoutes
        );

        systemd.services = lib.mkMerge [
          {
            "${ociBackend}-traefik" = lib.mkIf (traefikContainerRunning && staticRoutes != [ ]) {
              restartTriggers = map (route: route.configFile) staticRoutes;
            };
            traefik = lib.mkIf (config.mine.services.traefik.enable or false && staticRoutes != [ ]) {
              restartTriggers = map (route: route.configFile) staticRoutes;
            };
          }
        ];

        virtualisation.oci-containers.containers.traefik =
          lib.mkIf (traefikContainerRunning && staticRoutes != [ ])
            {
              cmd = [ "--providers.file.directory=/static" ];
              volumes = map (route: "${route.configFile}:/static/${route.identifier}.yaml:ro") staticRoutes;
              extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
            };
      };
    };
}
