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
          "${wallpapers}/Kurzgesagt_Galaxies.png"
          "${wallpapers}/blue_astronaut_in_space.png"
          "${wallpapers}/blue_mountains.jpg"
        ];

        wallpaper = [
          "DP-1,${wallpapers}/Kurzgesagt_Galaxies.png"
          "DP-2,${wallpapers}/blue_mountains.jpg"
          "DP-3,${wallpapers}/blue_astronaut_in_space.png"
        ];
      };

      hyprpaperConf = lib.thurs.toHyprconf {
        attrs = hyprpaperSettings;
        importantPrefixes = [
          "$"
          "monitor"
        ];
      };

      etcPath = "xdg/hypr/hyprpaper.conf";
    in
    {
      options.mine.desktop.hyprpaper = {
        enable = lib.mkEnableOption "Enable Hyprpaper Home-Manager config";
      };

      config = lib.mkIf cfg.enable {
        environment = {
          etc."${etcPath}".text = hyprpaperConf;
          systemPackages = [
            pkgs.hyprpaper
          ];
        };

        systemd.user.services.hyprpaper = {
          description = "autostart service for hyprpaper";
          documentation = [ "https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/" ];
          after = [ "graphical-session.target" ];
          bindsTo = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          reloadIfChanged = true;
          restartTriggers = [
            config.environment.etc.${etcPath}.source
          ];
          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.hyprpaper}";
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Restart = "always";
          };
        };
      };
    };
}
