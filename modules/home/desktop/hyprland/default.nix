{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.desktop.hyprland;
user = config.mine.user;
chrome-flags = "--ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy --enable-features=VaapiVideoDecoder --enable-features=UseOzonePlatform --ozone-platform=wayland";

in {
  options.mine.desktop.hyprland = {
    enable = mkEnableOption "Enable Hyprland Window Manager";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.sessionVariables = {
        XDG_CURRENT_SESSION = "hyprland";
        XDG_SESSION_TYPE = "wayland";
        QT_QPA_PLATFORM="wayland-egl";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      };

      wayland.windowManager.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;

        extraConfig = ''
          # MONITORS AND WORKSPACES
          monitor=DP-1, 2560x1440@165, 90x0, 1
          monitor=DP-2, 3840x1600@144, 0x1440, 1
          monitor=DP-3, 2560x1440@120, 3840x480, 1, transform, 3
          workspace = 1, monitor:DP-2
          workspace = 2, monitor:DP-2
          workspace = 3, monitor:DP-2
          workspace = 4, monitor:DP-2
          workspace = 5, monitor:DP-3
          workspace = 6, monitor:DP-3
          workspace = 7, monitor:DP-3
          workspace = 8, monitor:DP-1, gapsin:0, gapsout:0
          workspace = 9, monitor:DP-1
          workspace = 10, monitor:DP-1
          # RULES
          windowrulev2 = workspace 4 silent, class:(Bitwarden)
          windowrulev2 = workspace 5 silent, class:(discord)
          windowrulev2 = workspace 6 silent, class:(chrome-deezer.com__-Default)
          windowrulev2 = workspace 7 silent, class:(obsidian)
          windowrulev2 = workspace 8 silent, class:(chrome-youtube.com__-Default)
          windowrulev2 = maximize, class:(chrome-youtube.com__-Default)
          windowrulev2 = size 90%, class:(chrome-youtube.com__-Default)
        '';

        settings = {
          "$mod" = "SUPER";
          "dwindle" = {
            preserve_split = true;
            pseudotile = true;
            force_split = 2;
          };
          "master" = {
            new_is_master = true;
          };
          bindm =
          [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];
          bind =
          [
            "$mod, space, exec, fuzzel"
            "$mod, return, exec, kitty"
            "$mod, T, layoutmsg, togglesplit"
            "$mod, F, fullscreen"
            "$mod, G, exec, grim -g \"$(slurp)\" \"${user.homeDir}/pictures/screenshots/$(date +'%F_%H-%M-%S_slurp')\""
            "$mod_SHIFT, O, exec, obsidian"
            "$mod_SHIFT, B, exec, firefox"
            "$mod_SHIFT, G, exec, grim -g \"$(slurp)\" - | wl-copy"
            "$mod_SHIFT, F, fullscreen, 1"
            "$mod_SHIFT, O, exec, obsidian"
            "$mod_SHIFT, Y, exec, ${lib.getExe pkgs.chromium} ${chrome-flags} --app=https://youtube.com"
            "$mod_SHIFT, D, exec, ${lib.getExe pkgs.chromium} ${chrome-flags} --app=https://deezer.com"
            "$mod_SHIFT, P, exec, ${lib.getExe pkgs.chromium} ${chrome-flags} --app=https://192.168.20.80:32400"
            "$mod_SHIFT, Q, killactive"
            "$mod_SHIFT, X, exec, hyprlock"
            # Mouse Focus
            "$mod, H, movefocus, l"
            "$mod, L, movefocus, r"
            "$mod, K, movefocus, u"
            "$mod, J, movefocus, d"
            # Window Management
            "$mod_SHIFT, H, movewindow, l"
            "$mod_SHIFT, L, movewindow, r"
            "$mod_SHIFT, K, movewindow, u"
            "$mod_SHIFT, J, movewindow, d"
          ]
          ++ (
              # workspaces
              # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
              builtins.concatLists (builtins.genList (
                x: let
                ws = let
                c = (x + 1) / 10;
                in
                builtins.toString (x + 1 - (c * 10));
                in [
                "$mod, ${ws}, workspace, ${toString (x + 1)}"
                "$mod_SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
                )
              10)
             );
        };
      };

      home.packages = with pkgs; [
        # shell script start desktop apps
        (writeShellScriptBin "_desktop.restart" ''
          #/usr/bin/env bash

          systemctl --user restart desktop.service
          ${pkgs.discord}/bin/discord >/dev/null 2>&1 &
        '')
      ];

      systemd.user.services.desktop = {
        Unit = {
          Description = "Systemd oneshot to restart services linked to desktop.service";
          Documentation = "Coming soon...";
          After = [ "graphical-session-pre.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/sleep 1";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

    };
  };
}
