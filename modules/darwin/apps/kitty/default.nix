{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.apps.kitty;

in {
  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      casks = [
        "kitty"
      ];
    };
  };
}
