{ lib, config, pkgs, ... }:
with lib;
let

cfg = config.mine.nixos.utils;

in {
  options.mine.nixos.utils = {
    enable = mkEnableOption "utils";
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
