{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.hyprpaper;
  user = config.mine.user;

in
{
  options.mine.desktop.hyprpaper = {
    enable = mkEnableOption "Enable Hyprpaper Home-Manager config";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      services.hyprpaper = {
        enable = true;
        settings = {
          splash = false;
          preload = [
            # TODO: install these via derivation
            "${user.homeDir}/pictures/wallpapers/blue_astronaut_in_space.png"
            "${user.homeDir}/pictures/wallpapers/Kurzgesagt_Galaxies.png"
          ];

          wallpaper = [
            "DP-1,${user.homeDir}/pictures/wallpapers/Kurzgesagt_Galaxies.png"
            "DP-2,${user.homeDir}/pictures/wallpapers/blue_astronaut_in_space.png"
            "DP-3,${user.homeDir}/pictures/wallpapers/blue_astronaut_in_space.png"
          ];
        };
      };
    };
  };
}
