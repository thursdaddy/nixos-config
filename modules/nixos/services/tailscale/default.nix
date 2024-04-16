{ lib, config, ... }:
with lib;
let

  cfg = config.mine.services.tailscale;

in
{
  options.mine.services.tailscale = {
    enable = mkEnableOption "Enable Tailscale";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      extraUpFlags = [
        "--accept-dns=false"
      ];
    };
  };
}
