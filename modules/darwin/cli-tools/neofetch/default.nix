{ lib, config, ... }:
with lib;
let

  cfg = config.mine.cli-tools.neofetch;

in
{
  options.mine.cli-tools.neofetch = {
    enable = mkEnableOption "Enable Neofetch";
  };

  config = mkIf cfg.enable {
    homebrew.brews = [ "neofetch" ];
  };
}
