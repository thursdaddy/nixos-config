{ inputs, ... }:
{
  flake.modules.nixos.desktop =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.desktop.hypridle;

      patchedPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.hypridle-patched;
      notify-message = "${lib.getExe' pkgs.libnotify "notify-send"} \"$(date '+%A %I:%M:%S')\"";

      hypridleSettings = {
        general = {
          before_sleep_cmd = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
          after_sleep_cmd = "${lib.getExe' pkgs.systemd "hyprctl"} dispatch dpms on";
          lock_cmd = "${lib.getExe' pkgs.busybox "pidof"} hyprlock || ${lib.getExe pkgs.hyprlock}";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
            on-resume = "${notify-message} \"HyprIdle: Screen Unlocked!\"";
          }
          {
            timeout = 600;
            on-timeout = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms off";
            on-resume = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms on";
          }
          {
            timeout = 900;
            on-timeout = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
          }
        ];
      };

      hypridleConf = lib.thurs.toHyprconf {
        attrs = hypridleSettings;
      };

      etcPath = "xdg/hypr/hypridle.conf";
    in
    {
      options.mine.desktop.hypridle = {
        enable = lib.mkEnableOption "Enable hypridle";
      };

      config = lib.mkIf cfg.enable {
        systemd.user.services.hypridle = {
          description = "Hyrpidle";
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          serviceConfig = {
            ExecStart = "${lib.getExe patchedPkg}";
            Type = "simple";
            Restart = "always";
            RestartSec = "10s";
          };
        };

        environment.systemPackages = [
          patchedPkg
        ];

        environment.etc."${etcPath}".text = hypridleConf;

      };
    };
}
