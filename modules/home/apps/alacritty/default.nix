{ lib, config,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.alacritty;
user = config.mine.nixos.user;

in {
  options.mine.home.alacritty = {
    enable = mkOpt types.bool false "Enable Alacritty";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {

      programs.alacritty = {
        enable = true;
      };

    };
  };

}
