{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf types optionals;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.system.utils;

  dev = with pkgs; [
    glow
    jq
    nixfmt-rfc-style
    nixpkgs-fmt
    shellcheck
    statix
  ];
  sysadmin = with pkgs; [
    bind
    dig
    gnupg
    killall
    ncdu
    nmap
    (mkIf pkgs.stdenv.isLinux pinentry-all)
    wakeonlan
  ];

in
{
  options.mine.system.utils = {
    enable = mkOpt types.bool true "system utils";
    dev = mkEnableOption "Developer focused tooling";
    sysadmin = mkEnableOption "Sysadmin focused tooling";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      curl
      eza
      file
      fzf
      ripgrep
      tree
      unzip
      wget
    ] ++ optionals cfg.dev dev
    ++ optionals cfg.sysadmin sysadmin
    ++ optionals pkgs.stdenv.isDarwin [
      reattach-to-user-namespace
    ];
  };
}
