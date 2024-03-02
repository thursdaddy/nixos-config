{ lib, config,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.chrome;
user = config.mine.nixos.user;

in {
  options.mine.home.chrome = {
    enable = mkOpt types.bool false "Enable chrome";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {

      programs.google-chrome = {
        enable = true;
      };

    };
  };

}
