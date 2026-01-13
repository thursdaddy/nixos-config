{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.desktop.hyprland;
  network = config.mine.system.networking.networkmanager;

  chrome-flags = "--ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy --enable-features=VaapiVideoDecoder --enable-features=UseOzonePlatform --ozone-platform=wayland";

in
{
  options.mine.desktop.hyprland = {
    home = mkEnableOption "Enable Hyprland Home-Manager config";
  };

  config = mkIf cfg.home {
    home-manager.users.${user.name} = {
      home.sessionVariables = {
        XDG_CURRENT_SESSION = "hyprland";
        XDG_SESSION_TYPE = "wayland";
        QT_QPA_PLATFORM = "wayland-egl";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      };

      home.packages = with pkgs; [
        (mkIf network.applet networkmanagerapplet)
        bemoji
      ];

      services.network-manager-applet.enable = mkIf network.applet true;

      wayland.windowManager.hyprland = {
        enable = true;
        package = pkgs.hyprland;

        extraConfig = ''

          exec-once = steam
          exec-once = discord
          exec-once = obsidian

          # MONITORS AND WORKSPACES
          monitor=DP-1, 2560x1440@165, 90x0, 1
          monitor=DP-2, 3840x1600@144, 0x1440, 1
          monitor=DP-3, 2560x1440@120, 3840x480, 1, transform, 3
          workspace = 1, monitor:DP-2, gapsin:3, gapsout:3
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
          windowrulev2 = workspace 10 silent, class:(steam)
          windowrulev2 = workspace 4 silent, class:(Bitwarden)
          windowrulev2 = workspace 4 silent, class:(Proton Mail)
          windowrulev2 = workspace 5 silent, class:(discord)
          windowrulev2 = workspace 6 silent, class:(obsidian)
          windowrulev2 = workspace 8 silent, class:(chrome-youtube.com__-Default)
          windowrulev2 = maximize, class:(chrome-youtube.com__-Default)
          windowrulev2 = nodim, class:(chrome-youtube.com__-Default)
          windowrulev2 = nodim, class:(Vivaldi-stable)
          windowrulev2 = size 90%, class:(chrome-youtube.com__-Default)
          windowrulev2 = workspace 8 silent, class:(chrome-music.youtube.com__-Default)
          windowrulev2 = maximize, class:(chrome-music.youtube.com__-Default)
          windowrulev2 = nodim, class:(chrome-music.youtube.com__-Default)
          windowrulev2 = size 90%, class:(chrome-music.youtube.com__-Default)
          windowrulev2 = workspace 8 silent, class:(Vivaldi-stable), initialTitle:(192.168.10.189_/)
          windowrulev2 = maximize, class:(Vivaldi-stable), initialTitle:(192.168.10.189_/)
          windowrulev2 = nodim, class:(Vivaldi-stable), initialTitle:(192.168.10.189_/)
          windowrulev2 = workspace 9, class:(^steam_app_\d+$)
          windowrulev2 = nodim, class:(^steam_app_\d+$)
          windowrulev2 = fullscreen,class:(^steam_app_\d+$)
          windowrulev2 = renderunfocused,class:(^steam_app_\d+$)
        '';

        settings = {
          debug = {
            disable_logs = false;
          };

          "$mod" = "SUPER";

          env = [ "XCURSOR_SIZE,32" ];
          general = {
            layout = "dwindle";
            gaps_in = 5;
            gaps_out = 5;
          };

          group = {
            "col.border_active" = "0xffffffff";
            "col.border_inactive" = "0xff000000";
            groupbar = {
              height = "14";
              font_size = "12";
              indicator_height = "2";
              text_color = "0xffffffff";
              "col.active" = "0xff88c0d0";
              "col.inactive" = "0xff4c566a";
            };
          };

          master = {
            new_status = true;
          };

          misc = {
            key_press_enables_dpms = true;
          };

          binds = {
            allow_workspace_cycles = true;
          };

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 4, myBezier"
          ];

          decoration = {
            dim_inactive = true;
            dim_strength = 0.35;
            rounding = 5;
          };

          bindm = [
            "$mod, mouse:272, resizewindow"
            "$mod, mouse:273, movewindow"
          ];

          bind = [
            "$mod, space, exec, fuzzel"
            "$mod_SHIFT, space, togglefloating"
            "$mod, return, exec, ghostty"
            "$mod_SHIFT, return, exec, [float;noanim] ghostty"
            "$mod, F, fullscreen"
            "$mod, E, exec, bemoji -c"
            "$mod, G, exec, grim -g \"$(slurp)\" \"${user.homeDir}/pictures/screenshots/$(date +'%F_%H-%M-%S_slurp')\""
            "$mod_SHIFT, B, exec, vivaldi"
            "$mod_SHIFT, D, exec, discord"
            "$mod_SHIFT, F, fullscreen, 1"
            "$mod_SHIFT, G, exec, grim -g \"$(slurp)\" - | wl-copy"
            "$mod_SHIFT, O, exec, obsidian"
            "$mod_SHIFT, P, exec, ${lib.getExe pkgs.vivaldi} --app=https://192.168.10.189:32400"
            "$mod_SHIFT, Q, killactive"
            "$mod_SHIFT, X, exec, loginctl lock-session && sleep 2 && hyprctl dispatch dpms off && hyprlock"
            "$mod_SHIFT, Z, exec, loginctl lock-session && sleep 2 && hyprctl dispatch dpms off && systemctl suspend"
            "$mod_SHIFT, Y, exec, ${lib.getExe pkgs.chromium} ${chrome-flags} --app=https://youtube.com"
            "$mod_SHIFT, M, exec, ${lib.getExe pkgs.chromium} ${chrome-flags} --app=https://music.youtube.com"
            # Mouse Focus
            "$mod, H, movefocus, l"
            "$mod, L, movefocus, r"
            "$mod, K, movefocus, u"
            "$mod, J, movefocus, d"
            # Window Management
            "$mod_SHIFT, H, movewindoworgroup, l"
            "$mod_SHIFT, L, movewindoworgroup, r"
            "$mod_SHIFT, K, movewindoworgroup, u"
            "$mod_SHIFT, J, movewindoworgroup, d"
            # Workspace Switcher
            "$mod, TAB, workspace, previous"
            "$mod, T, togglegroup"
            "$mod, C, changegroupactive, b"
            "$mod, V, changegroupactive, f"
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (
              builtins.genList (
                x:
                let
                  ws =
                    let
                      c = (x + 1) / 10;
                    in
                    builtins.toString (x + 1 - (c * 10));
                in
                [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod_SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              ) 10
            )
          );
        };
      };
    };
  };
}
