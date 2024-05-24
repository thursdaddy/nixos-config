{ lib, config, ... }:
with lib;
let

  cfg = config.mine.cli-tools.homebrew;

in
{
  options.mine.cli-tools.homebrew = {
    enable = mkEnableOption "Enable Homebrew";
  };

  config = mkIf cfg.enable {
    homebrew.enable = true;
  };
}
