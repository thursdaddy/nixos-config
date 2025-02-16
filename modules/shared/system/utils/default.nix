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
      bind
      curl
      dig
      file
      fzf
      jq
      killall
      ncdu
      nixpkgs-fmt
      nmap
      ripgrep
      shellcheck
      statix
      tree
      unzip
      wget
    ] ++ optionals pkgs.stdenv.isDarwin [
      reattach-to-user-namespace
    ];
  };
}
