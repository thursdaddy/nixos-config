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
      inherit (inputs.self.packages.${pkgs.stdenv.hostPlatform.system}) wallpapers;

      cfg = config.mine.desktop.hyprlock;

      hyprlockSettings = {
        general = {
          ignore_empty_input = true;
        };

        animations = {
          enabled = true;
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
            pkgs.hyprlock
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
            Type = "forking";
            Environment = [
              "WAYLAND_DISPLAY=wayland-1"
              "XDG_RUNTIME_DIR=/run/user/1000"
            ];
            ExecCondition = "${pkgs.bash}/bin/bash -c '! ${lib.getExe' pkgs.busybox "pidof"} hyprlock'";
            ExecStart = "${pkgs.bash}/bin/bash -c '${lib.getExe pkgs.hyprlock} --grace 3 & sleep 0.5'";
            Restart = "no";
          };
        };
      };
    };
}
