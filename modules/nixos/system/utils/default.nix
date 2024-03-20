{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.utils;

in {
  options.mine.system.utils = {
    enable = mkEnableOption "Enable various system utils";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      curl
      file
      fzf
      glow
      dig
      jq
      killall
      nmap
      ripgrep
      unzip
      usbutils
      pciutils
      wget
    ];
  };
}
