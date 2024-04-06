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
      gnumake
      hdparm
      jq
      killall
      ncdu
      nmap
      pciutils
      ripgrep
      tree
      unzip
      usbutils
      wget
    ];
  };
}
