{ lib, config,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.firefox;
user = config.mine.nixos.user;

in {
  options.mine.home.firefox = {
    enable = mkOpt types.bool true "Enable Firefox";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {

      programs.firefox = {
        enable = true;
      };

    };
  };

}
