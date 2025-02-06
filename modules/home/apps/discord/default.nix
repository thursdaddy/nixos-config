{ lib, config, pkgs, ... }:
let

  inherit (lib) mkIf types;
  inherit (lib.thurs) mkOpt;
  inherit (config.mine) user;
  cfg = config.mine.apps.discord;

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
