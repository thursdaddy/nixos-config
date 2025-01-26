{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.proton;

in
{
  options.mine.apps.proton = {
    enable = mkEnableOption "proton app suite";
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "protonvpn" "proton-mail" ];
  };
}
