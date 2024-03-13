{ lib, config,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.kitty;
user = config.mine.nixos.user;

in {
  options.mine.home.kitty = {
    enable = mkOpt types.bool false "Enable Kitty";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {

      programs.kitty = {
        enable = true;
        theme = "Gruvbox Material Dark Hard";

        settings = {
          scrollback_lines = "20000";
          enable_audio_bell = false;
          background_opacity = "0.9";
        };
      };

    };
  };

}
