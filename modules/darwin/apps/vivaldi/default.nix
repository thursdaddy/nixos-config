{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
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
