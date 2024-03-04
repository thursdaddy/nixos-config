{ pkgs, lib, config, ... }:
with lib;
let
cfg = config.mine.nixos.bottom;

in {
  options.mine.nixos.bottom = {
    enable = mkEnableOption "Enable bottom";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.bottom
    ];

  };

}
