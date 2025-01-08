{ lib, config, inputs, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.hyprpaper;
  inherit (config.mine) user;
  inherit (inputs.self.packages.${pkgs.system}) wallpapers;

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
            "${wallpapers}/wallpapers/blue_astronaut_in_space.png"
            "${wallpapers}/wallpapers/Kurzgesagt_Galaxies.png"
          ];

          wallpaper = [
            "DP-1,${wallpapers}/wallpapers/Kurzgesagt_Galaxies.png"
            "DP-2,${wallpapers}/wallpapers/blue_astronaut_in_space.png"
            "DP-3,${wallpapers}/wallpapers/blue_astronaut_in_space.png"
          ];
        };
      };
    };
  };
}
