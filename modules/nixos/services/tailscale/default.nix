{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.services.tailscale;

in
{
  options.mine.services.tailscale = {
    enable = mkEnableOption "Enable Tailscale";
    authKeyFile = mkOpt (types.nullOr types.path) null "authKeyFile path";
    extraUpFlags = mkOpt (types.listOf types.str) [ ] "Tailscale up flags";
    useRoutingFeatures = mkOpt (types.enum [ "none" "client" "server" "both" ]) "none" "Tailscale routingFeatures";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.mine.services.tailscale.authKeyFile;
      useRoutingFeatures = config.mine.services.tailscale.useRoutingFeatures;
      extraUpFlags = config.mine.services.tailscale.extraUpFlags;
    };

  };
}
