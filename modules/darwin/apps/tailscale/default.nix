{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.tailscale;

in
{
  options.mine.apps.tailscale = {
    enable = mkEnableOption "Install tailscale";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "tailscale" ];
  };
}
