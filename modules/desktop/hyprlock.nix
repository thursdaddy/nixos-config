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
      inherit (pkgs) wallpapers;

      cfg = config.mine.desktop.hyprlock;

      hyprlockSettings = {
        general = {
          ignore_empty_input = true;
        };

        animations = {
          enabled = false;
        };

        background = [
          {
            monitor = "";
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
          text = ''cmd[update:1000] echo "<b>$(date +'%_I:%M:%S')</b>"'';
          text_align = "center";
          color = "rgba(255, 255, 255, 1.0)";
          font_size = "80";
          font_family = "Hack Nerd Fonts";
          position = "0, 80";
          halign = "center";
          valign = "center";
        };
      };

      hyprlockConf = lib.thurs.toHyprconf {
        attrs = hyprlockSettings;
        importantPrefixes = [
          "$"
          "bezier"
          "monitor"
          "size"
          "source"
        ];
      };

      etcDir = "xdg/hypr/hyprlock.conf";
    in
    {
      options.mine.desktop.hyprlock = {
        enable = lib.mkEnableOption "Enable hyprlock";
      };

      config = lib.mkIf cfg.enable {
        environment = {
          etc."${etcDir}".text = hyprlockConf;
          systemPackages = [
            pkgs.unstable.hyprlock
            pkgs.systemd-lock-handler
          ];
        };

        security.pam.services.hyprlock = { };

        services.systemd-lock-handler.enable = true;

        systemd.user.services.hyprlock-targets = {
          description = "Hyprlock managed via targets and systemd-lock-handler";
          before = [
            "sleep.target"
            "lock.target"
          ];
          wantedBy = [
            "sleep.target"
            "lock.target"
          ];
          onSuccess = [ "unlock.target" ];
          serviceConfig = {
            Type = "simple";
            ExecCondition = "${pkgs.bash}/bin/bash -c '! ${lib.getExe' pkgs.busybox "pidof"} hyprlock'";
            ExecStart = "${lib.getExe pkgs.unstable.hyprlock} --immediate-render --no-fade-in";
            ExecStartPost = "${pkgs.coreutils}/bin/sleep 2";
            Restart = "on-failure";
            RestartSec = 1;
          };
        };
      };
    };
}
