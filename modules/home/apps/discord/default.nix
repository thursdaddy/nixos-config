{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.apps.discord;
  user = config.mine.user;

in {
  options.mine.apps.discord = {
    enable = mkOpt types.bool false "Install Discord";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "discord"
    ];

    # hopefully mkIf are temporary until I can figure out how to get home-manager apps to show up in Spotlight / Dock
    home-manager.users.${user.name} = mkIf (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86) {
      home.packages = with pkgs; [ discord ];
    };
  };
}
