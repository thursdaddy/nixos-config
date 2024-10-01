{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.protonvpn;

in
{
  options.mine.apps.protonvpn = {
    enable = mkEnableOption "protonvpn";
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "protonvpn" ];
  };
}
