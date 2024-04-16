{ lib, config, ... }:
with lib;
let

  cfg = config.mine.tools.sops;

in {
  options.mine.tools.sops = {
    enable = mkEnableOption "Enable sops";
  };

  config = mkIf cfg.enable {
    homebrew.brews = [ "sops" ];
  };
}
