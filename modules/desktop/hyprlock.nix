{ inputs, ... }:
{
  flake.modules.generic.desktop =
    {
      lib,
      ...
    }:
    {
      options.mine.desktop.hyprlock = {
        enable = lib.mkEnableOption "Enable hyprlock";
      };
    };

  flake.modules.nixos.desktop =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.desktop.hyprlock;
      inherit (config.mine.base) user;
    in
    {
      config = lib.mkIf cfg.enable {
        systemd.services.lock-on-suspend = {
          description = "Lock on suspend";
          wantedBy = [
            "sleep.target"
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
          ];
          before = [
            "sleep.target"
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
          ];
          environment = {
            DISPLAY = ":0";
            WAYLAND_DISPLAY = "wayland-1";
            XDG_RUNTIME_DIR = "/run/user/1000";
          };
          serviceConfig = {
            Type = "simple";
            ExecStart = "${lib.getExe' pkgs.busybox "pidof"} hyprlock || ${lib.getExe pkgs.hyprlock}";
            User = user.name;
          };
        };

        # hyprlock needs a second to complete before suspending
        systemd.services.sleep-before-suspend = {
          description = "Sleep before suspend";
          wantedBy = [
            "sleep.target"
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
          ];
          before = [
            "sleep.target"
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
          ];
          serviceConfig = {
            Type = "simple";
            ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 1";
            ExecStart = "${lib.getExe' pkgs.coreutils "true"}";
          };
        };
      };
    };

  flake.modules.homeManager.desktop =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (inputs.self.packages.${pkgs.stdenv.hostPlatform.system}) wallpapers;
      cfg = osConfig.mine.desktop.hyprlock;
    in
    {
      programs.hyprlock = lib.mkIf cfg.enable {
        enable = true;
        package = pkgs.unstable.hyprlock;
        settings = {
          general = {
            grace = 3;
            ignore_empty_input = true;
          };

          background = [
            {
              path = "${wallpapers}/blue_astronaut_in_space.png";
            }
          ];

          input-field = [
            {
              size = "300, 60";
              outline_thickness = 2;
              monitor = "DP-1";
              dots_size = 0.05;
              dots_spacing = 0.05;
              dots_center = true;
              outer_color = "rgba(0, 0, 0, 0)";
              inner_color = "rgba(0, 0, 0, 0.5)";
              font_color = "rgb(200, 200, 200)";
              fade_on_empty = true;
              fade_timeout = 5000;
              placeholder_text = "PASSWORD";
              position = "0, -120";
            }
          ];

          label = {
            monitor = "DP-1";
            text = ''cmd[update:10] echo "<b>$(date +'%_I:%M:%S')</b>"'';
            text_align = "center";
            color = "rgba(255, 255, 255, 1.0)";
            font_size = "80";
            font_family = "Hack Nerd Fonts";
            position = "0, 80";
            halign = "center";
            valign = "center";
          };
        };
      };
    };
}
