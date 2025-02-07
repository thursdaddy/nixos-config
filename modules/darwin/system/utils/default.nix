{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.utils;

in
{
  options.mine.system.utils = {
    enable = mkEnableOption "system utils";
  };

  config = mkIf cfg.enable {
    homebrew.brews = [
      "bind"
      "fzf"
      "jq"
      "ncdu"
      "ripgrep"
      "reattach-to-user-namespace"
      "statix"
      "wakeonlan"
    ];
  };
}
