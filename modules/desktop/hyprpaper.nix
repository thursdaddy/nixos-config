{ inputs, ... }:
{
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (inputs.self.packages.${pkgs.stdenv.hostPlatform.system}) wallpapers;
      cfg = config.mine.desktop.hyprpaper;

      hyprpaperSettings = {
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

      hyprpaperConf = lib.thurs.toHyprconf {
        attrs = hyprpaperSettings;
      };

      etcDir = "hypr/hyprpaper.conf";
    in
    {
      options.mine.desktop.hyprpaper = {
        enable = lib.mkEnableOption "Enable Hyprpaper Home-Manager config";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.hyprpaper
        ];

        environment.etc."${etcDir}".text = hyprpaperConf;

        systemd.user.services.hyprpaper = {
          description = "autostart service for hyprpaper";
          documentation = [ "https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/" ];
          after = [ "graphical-session.target" ];
          bindsTo = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper -c /etc/${etcDir}";
            Restart = "always";
            X-Restart-Triggers = [
              config.environment.etc.${etcDir}.source
            ];
          };
        };
      };
    };
}
