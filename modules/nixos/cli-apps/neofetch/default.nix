{ pkgs, lib, config, ... }:
with lib;
let
cfg = config.mine.nixos.neofetch;

in {
  options.mine.nixos.neofetch = {
    enable = mkEnableOption "Enable Neofetch";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.neofetch
    ];

  };

}
