{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.system.nix.flakes;

in {
  options.mine.system.nix.flakes = {
    enable = mkEnableOption "Enable Flakes";
  };

  config = mkIf cfg.enable {
    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };
  };
}
