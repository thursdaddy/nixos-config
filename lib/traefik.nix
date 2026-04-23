{ lib }:
{
  mkTraefikFile =
    {
      name,
      port,
      config,
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
              entryPoints = ["websecure"]
              [http.routers.${name}.tls]
                certResolver = "letsencrypt"

          [http.services]
            [http.services.${name}.loadBalancer]
              [[http.services.${name}.loadBalancer.servers]]
                url = "http://${ip}:${toString port}"
        '';
      };
    };
}
