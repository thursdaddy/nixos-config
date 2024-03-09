{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.screenshots;

in {
  options.mine.nixos.screenshots = {
    enable = mkOpt types.bool false "Enable screenshots with grim and slurp";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      grim
      slurp
    ];
  };

}
