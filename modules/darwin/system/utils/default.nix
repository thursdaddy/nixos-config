{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.utils;

in {
  options.mine.system.utils = {
    enable = mkEnableOption "system utils";
  };

  config = mkIf cfg.enable {
    homebrew.brews = [
      "fzf"
      "bind"
      "jq"
      "ripgrep"
    ];
  };

}
