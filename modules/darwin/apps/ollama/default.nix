{ lib, config, ... }:
let

  inherit (lib) mkEnableOption;
  cfg = config.mine.apps.ollama;

in
{
  options.mine.apps.ollama = {
    enable = mkEnableOption "ollama";
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "ollama" ];
  };
}
