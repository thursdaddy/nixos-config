{ inputs, ... }:
{
  flake.modules.generic.desktop =
    { lib, ... }:
    {
      options.mine.desktop.hyprpaper = {
        enable = lib.mkEnableOption "Enable Hyprpaper Home-Manager config";
      };
    };

  flake.modules.homeManager.desktop =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (inputs.self.packages.${pkgs.stdenv.hostPlatform.system}) wallpapers;
      cfg = osConfig.mine.desktop.hyprpaper;
    in
    {
      config = lib.mkIf cfg.enable {
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
