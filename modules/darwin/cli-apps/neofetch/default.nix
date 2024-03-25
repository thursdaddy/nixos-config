{ lib, config, ... }:
with lib;
let

  cfg = config.mine.cli-apps.neofetch;

in {
  options.mine.cli-apps.neofetch = {
    enable = mkEnableOption "Enable Neofetch";
  };

  config = mkIf cfg.enable {
    homebrew.brews = [ "neofetch" ];
  };
}
