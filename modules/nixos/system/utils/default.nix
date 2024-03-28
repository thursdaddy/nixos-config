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
      dig
      file
      fzf
      glow
      hdparm
      jq
      killall
      ncdu
      nmap
      pciutils
      ripgrep
      unzip
      usbutils
      wget
    ];
  };
}
