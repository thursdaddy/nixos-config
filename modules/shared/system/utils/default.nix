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
      eza
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
      nixfmt-rfc-style
      statix
      tree
      unzip
      wget
    ] ++ optionals pkgs.stdenv.isDarwin [
      reattach-to-user-namespace
    ];
  };
}
