{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.atticd;
in
{
  options.mine.services.atticd = {
    enable = mkEnableOption "Attic server for nixpkg cache";
  };

  config = mkIf cfg.enable {
    environment.etc = mkIf config.mine.container.traefik.enable {
      "traefik/attic.yml" = {
        text = builtins.readFile ./traefik.yml;
      };
    };

    sops = {
      secrets."attic/SERVER_TOKEN_BASE64_SECRET" = { };
      secrets."attic/DB_PASS" = { };
      templates."atticd_base64.token".content = ''
        ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="${
          config.sops.placeholder."attic/SERVER_TOKEN_BASE64_SECRET"
        }"
      '';
      templates."atticd_config.toml" = {
        owner = "thurs";
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

    networking.firewall.allowedTCPPorts = [ 5454 ];

    systemd.services.atticd.serviceConfig = {
      User = lib.mkForce "thurs";
      ExecStart = lib.mkForce "${lib.getExe config.services.atticd.package} -f ${
        config.sops.templates."atticd_config.toml".path
      } --mode monolithic";
    };

    services.atticd = {
      enable = true;
      # brute forcing settings file to set postgresql connection string via sops template
      # https://github.com/zhaofengli/attic/pull/207
      settings = { };
      environmentFile = config.sops.templates."atticd_base64.token".path;
    };
  };
}
