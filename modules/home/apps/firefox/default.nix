{ lib, config,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.firefox;
user = config.mine.user;

in {
  options.mine.home.firefox = {
    enable = mkOpt types.bool false "Enable Firefox";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

      programs.firefox = {
        enable = true;
      };

    };
  };

}
