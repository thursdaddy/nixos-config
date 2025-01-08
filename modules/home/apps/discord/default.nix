{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.apps.discord;
  inherit (config.mine) user;

in
{
  options.mine.apps.discord = {
    enable = mkOpt types.bool false "Install Discord";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "discord"
    ];

    home-manager.users.${user.name} = {
      home.packages = with pkgs; [ discord ];
    };
  };
}
