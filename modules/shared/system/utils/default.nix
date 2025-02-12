{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf optionals;
  cfg = config.mine.system.utils;

in
{
  options.mine.system.utils = {
    enable = mkEnableOption "system utils";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nixpkgs-fmt
      bind
      gnupg
      fzf
      jq
      ncdu
      ripgrep
      wakeonlan
      statix
      curl
      dig
      file
      fzf
      glow
      jq
      killall
      nmap
      shellcheck
      tree
      unzip
      wget
      yt-dlp
    ] ++ optionals pkgs.stdenv.isDarwin [
      reattach-to-user-namespace
    ] ++ optionals pkgs.stdenv.isLinux [
      pinentry-all
    ];
  };
}
