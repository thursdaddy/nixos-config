{ lib }:
{
  mkTraefikFile =
    {
      name,
      domain ? (
        config.mine.services.traefik.rootDomainName or config.mine.containers.traefik.rootDomainName
      ),
      ip ? "127.0.0.1",
      port,
      config,
    }:
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
