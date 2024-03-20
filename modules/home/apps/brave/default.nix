{ lib, config,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.brave;
user = config.mine.user;

in {
  options.mine.home.brave = {
    enable = mkOpt types.bool false "Enable brave";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {

      programs.brave = {
        enable = true;
      };

    };
  };

}
