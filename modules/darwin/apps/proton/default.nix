{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
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
