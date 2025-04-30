{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.attic;
in
{
  options.mine.services.attic = {
    enable = mkEnableOption "Attic cache";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 8080 ];

    environment.systemPackages = [
      pkgs.attic-client
    ];

    services.atticd = {
      enable = true;
      environmentFile = "/var/lib/private/atticd/secret.token";
    };
  };
}
