{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.homebrew;

in
{
  options.mine.cli-tools.homebrew = {
    enable = mkEnableOption "Enable Homebrew";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        upgrade = true;
      };
    };
  };
}
