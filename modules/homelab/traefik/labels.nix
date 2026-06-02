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
        name: appConfig: globalConfig.mine.containers.${name}.enable or false
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

      containerRoutes = lib.flatten (
        lib.mapAttrsToList (
          name: homelabConfig:
          let
            c = homelabConfig.traefik.container;
          in
          if c.port != null then
            let
              subdomain = if c.subDomain != "" then c.subDomain else name;
              domain =
                if homelabConfig.traefik.domain != hostData.rootDomainName then
                  homelabConfig.traefik.domain
                else
                  hostData.rootDomainName;
              fqdn = "${subdomain}.${domain}";
              entryPoint = if c.tailscale then "tailscale" else "websecure";
            in
            [
              {
                inherit name fqdn entryPoint;
                port = c.port;
              }
            ]
          else
            [ ]
        ) activeApps
      );

    in
    {
      config = {
        systemd.services = lib.mkMerge [
          (builtins.listToAttrs (
            map (
              route:
              lib.nameValuePair "init-${ociBackend}-network-${route.name}" (
                lib.mkIf (ociBackend != "") {
                  description = "Create ${ociBackend} networks for Traefik isolation";
                  wantedBy = [ "multi-user.target" ];
                  before = [ "${ociBackend}-${route.name}.service" ];
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart = [
                      "-${lib.getExe pkgs.${ociBackend}} network create traefik-${route.name}"
                      "-${lib.getExe pkgs.${ociBackend}} network create ${route.name}"
                    ];
                  };
                }
              )
            ) containerRoutes
          ))
        ];

        virtualisation.oci-containers = {
          containers = lib.mkMerge [
            {
              traefik = lib.mkIf (traefikContainerRunning && containerRoutes != [ ]) {
                networks = map (route: "traefik-${route.name}") containerRoutes;
              };
            }

            (builtins.listToAttrs (
              map (
                route:
                lib.nameValuePair route.name (
                  lib.mkIf traefikContainerRunning {
                    networks = [
                      "traefik-${route.name}"
                      "${route.name}"
                    ];
                    labels = {
                      "traefik.enable" = "true";
                      "traefik.docker.network" = "traefik-${route.name}";
                      "traefik.http.routers.${route.name}.tls" = "true";
                      "traefik.http.routers.${route.name}.tls.certresolver" = "letsencrypt";
                      "traefik.http.routers.${route.name}.entrypoints" = route.entryPoint;
                      "traefik.http.routers.${route.name}.rule" = "Host(`${route.fqdn}`)";
                      "traefik.http.services.${route.name}.loadbalancer.server.port" = builtins.toString route.port;
                    };
                  }
                )
              ) containerRoutes
            ))
          ];
        };
      };
    };
}
