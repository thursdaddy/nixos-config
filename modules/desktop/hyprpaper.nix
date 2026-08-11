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
      inherit (pkgs) wallpapers;
      cfg = config.mine.desktop.hyprpaper;

      hyprpaperSettings = {
        splash = false;
        ipc = true;
        wallpaper = [
          {
            monitor = "DP-1";
            path = "${wallpapers}/Kurzgesagt_Galaxies.png";
          }
          {
            monitor = "DP-2";
            path = "${wallpapers}/blue_mountains.jpg";
          }
          {
            monitor = "DP-3";
            path = "${wallpapers}/blue_astronaut_in_space.png";
          }
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
            ExecStart = "${lib.getExe pkgs.hyprpaper} -c /etc/${etcPath}";
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Restart = "always";
          };
        };
      };
    };
}
