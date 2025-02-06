{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.vivaldi;

in
{
  options.mine.apps.vivaldi = {
    enable = mkEnableOption "Install Vivaldi";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "vivaldi" ];
  };
}
