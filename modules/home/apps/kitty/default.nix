{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.kitty;
  user = config.mine.user;

in
{
  options.mine.apps.kitty = {
    enable = mkEnableOption "Enable Kitty";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.kitty = {
        enable = true;
        theme = "Hardcore";
        font = {
          name = "Hack Nerd Font";
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
