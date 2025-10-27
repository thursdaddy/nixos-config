{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let

  inherit (lib) mkIf mkEnableOption;
  inherit (config.mine) user;
  inherit (inputs.self.packages.${pkgs.system}) wallpapers;
  cfg = config.mine.desktop.hyprpaper;

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
            "${wallpapers}/blue_astronaut_in_space.png"
            "${wallpapers}/blue_mountains.jpg"
            "${wallpapers}/Kurzgesagt_Galaxies.png"
          ];

          wallpaper = [
            "DP-1,${wallpapers}/Kurzgesagt_Galaxies.png"
            "DP-2,${wallpapers}/blue_mountains.jpg"
            "DP-3,${wallpapers}/blue_astronaut_in_space.png"
          ];
        };
      };
    };
  };
}
