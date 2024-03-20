{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.discord;
user = config.mine.user;

in {
  options.mine.home.discord = {
    enable = mkOpt types.bool false "Enable Firefox";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [ discord ];

    };
  };

}
