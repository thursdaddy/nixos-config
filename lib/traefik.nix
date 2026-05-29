{ lib }:
{
  mkTraefikFile =
    {
      name,
      port,
      config,
      entryPoint ? "websecure",
      ...
    }@args:
    let
      domain =
        args.domain
          or (config.mine.services.traefik.rootDomainName or config.mine.containers.traefik.rootDomainName);

      ip =
        args.ip or (
          if config.mine.services.traefik.enable or false then
            "127.0.0.1"
          else if config.mine.containers.traefik.enable or false then
            "host.docker.internal"
          else
            "127.0.0.1"
        );
    in
    {
      name = "traefik/providers/${name}.toml";
      value = {
        text = ''
          [http.routers]
            [http.routers.${name}]
              rule = "Host(`${name}.${domain}`)"
              service = "${name}"
              entryPoints = ["${entryPoint}"]
              [http.routers.${name}.tls]
                certResolver = "letsencrypt"

          [http.services]
            [http.services.${name}.loadBalancer]
              [[http.services.${name}.loadBalancer.servers]]
                url = "http://${ip}:${toString port}"
        '';
      };
    };

  mkTraefikConfig =
    {
      name,
      port,
      config,
      tailscale ? false,
      ...
    }@args:
    let
      domain =
        args.domain
          or (config.mine.services.traefik.rootDomainName or config.mine.containers.traefik.rootDomainName);
      ip =
        args.ip or (
          if tailscale then
            config.mine.base.networking.meta.tailscaleIp
          else if config.mine.services.traefik.enable or false then
            "127.0.0.1"
          else if config.mine.containers.traefik.enable or false then
            "host.docker.internal"
          else
            "127.0.0.1"
        );
      entryPoint = if tailscale then "tailscale" else "websecure";
    in
    {
      environment.etc."traefik/providers/${name}.toml".text = ''
        [http.routers]
          [http.routers.${name}]
            rule = "Host(`${name}.${domain}`)"
            service = "${name}"
            entryPoints = ["${entryPoint}"]
            [http.routers.${name}.tls]
              certResolver = "letsencrypt"

        [http.services]
          [http.services.${name}.loadBalancer]
            [[http.services.${name}.loadBalancer.servers]]
              url = "http://${ip}:${toString port}"
      '';

      virtualisation.oci-containers.containers.traefik =
        lib.mkIf (config.mine.containers.traefik.enable or false)
          {
            extraOptions = [
              "--add-host=host.docker.internal:host-gateway"
            ];
          };
    };
}
