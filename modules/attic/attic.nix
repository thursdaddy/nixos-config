_: {
  flake.modules.nixos.attic =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      name = "attic";
      port = 5454;
    in
    {
      services.atticd = {
        enable = true;
        environmentFile = config.sops.templates."atticd_base64.token".path;
      };

      # Brute forcing settings file to set postgresql connection string via sops template
      # https://github.com/zhaofengli/attic/pull/207
      systemd.services.atticd.serviceConfig = {
        ExecStart = lib.mkForce "${lib.getExe config.services.atticd.package} -f ${
          config.sops.templates."atticd_config.toml".path
        } --mode monolithic";
      };

      # Since I am using a sops template for the config file and setting its owner to "atticd"
      # I need to create the user and group or sops will error.
      users.groups."atticd" = { };
      users.users."atticd" = {
        isSystemUser = true;
        group = "atticd";
      };

      sops = {
        secrets = {
          "attic/SERVER_TOKEN_BASE64_SECRET" = { };
          "attic/DB_PASS" = {
            owner = "atticd";
          };
        };
        templates = {
          "atticd_base64.token".content = ''
            ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="${
              config.sops.placeholder."attic/SERVER_TOKEN_BASE64_SECRET"
            }"
          '';
          "attic-db".content = ''
            POSTGRES_PASSWORD=${config.sops.placeholder."attic/DB_PASS"}
          '';
          "atticd_config.toml" = {
            owner = "atticd";
            content = ''
              listen = "[::]:5454"

              [chunking]
              avg-size = 65536
              max-size = 262144
              min-size = 16384
              nar-size-threshold = 65536

              [database]
              url ="postgresql://attic:${config.sops.placeholder."attic/DB_PASS"}@localhost:54545/attic"

              [storage]
              path = "/var/lib/atticd/storage"
              type = "local"
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 5454 ];

      virtualisation.oci-containers.containers.attic-db = {
        image = "postgres:17.6-alpine";
        hostname = "attic-db";
        ports = [
          "0.0.0.0:54545:5432"
        ];
        volumes = [
          "/opt/configs/attic/db:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=traefik"
          "--pull=always"
        ];
        environmentFiles = [
          config.sops.templates."attic-db".path
        ];
        environment = {
          POSTGRES_USER = "attic";
          POSTGRES_DB = "attic";
          PGDATA = "/var/lib/postgresql/data/pgdata";
        };
        labels = {
          "enable.versions.check" = "false";
        };
      };

      environment.etc =
        let
          traefik = lib.thurs.mkTraefikFile {
            inherit config;
            inherit name;
            inherit port;
          };
          alloyJournal = lib.thurs.mkAlloyJournal {
            inherit name;
            serviceName = "atticd";
          };
        in
        builtins.listToAttrs [
          traefik
          alloyJournal
        ];
    };
}
