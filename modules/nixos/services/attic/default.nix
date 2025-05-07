{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.attic;
in
{
  options.mine.services.attic = {
    enable = mkEnableOption "Attic server for nixpkg cache";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 8080 ];

    environment.etc = mkIf config.mine.container.traefik.enable {
      "traefik/attic.yml" = {
        text = builtins.readFile ./traefik.yml;
      };
    };

    services.atticd = {
      enable = true;
      environmentFile = "/var/lib/private/atticd/secret.token";
    };
  };
}
