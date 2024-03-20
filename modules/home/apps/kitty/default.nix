{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.apps.kitty;
user = config.mine.user;

in {
  options.mine.apps.kitty = {
    enable = mkOpt types.bool false "Enable Kitty";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.kitty = {
        enable = true;
        theme = "Tomorrow Night";
        font = {
          name = "HackNF-Regular";
        };

        settings = {
          scrollback_lines = "20000";
          enable_audio_bell = false;
          background_opacity = "0.9";
        };
      };
    };
  };
}
