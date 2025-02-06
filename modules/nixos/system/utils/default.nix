{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.utils;

in
{
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
      shellcheck
      statix
      smartmontools
      tree
      unzip
      usbutils
      wget
      yt-dlp
    ];
  };
}
