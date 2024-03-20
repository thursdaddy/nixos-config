{ lib, config, ... }:
with lib;
let

  cfg = config.mine.cli-apps.homebrew;

in {
  options.mine.cli-apps.homebrew = {
    enable = mkEnableOption "Enable Homebrew";
  };

  config = mkIf cfg.enable {
    homebrew.enable = true;
  };
}
