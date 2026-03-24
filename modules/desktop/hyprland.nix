_: {
  flake.modules.nixos.desktop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.mine.desktop.hyprland;
      inherit (config.mine.base) user;

      hyprlandSettings = {
        "$mod" = "SUPER";

        animations = {
          enabled = true;
          bezier = [
            "overshot, 0.05, 0.9, 0.1, 1.1"
            "easeOutQuint, 0.23, 1, 0.32, 1"
          ];
          animation = [
            "windowsIn, 1, 5, easeOutQuint, slidefade"
            "windowsOut, 1, 3, easeOutQuint, popin 50%"
            "windowsMove, 1, 3, easeOutQuint, popin 50%"
            "workspaces, 1, 5, overshot, slidevert"
            "fade, 1, 5, default"
            "border, 1, 20, default" # Slow border color fade
          ];
        };

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
          "$mod_SHIFT, P, exec, plex-desktop"
          "$mod_SHIFT, Q, killactive"
          "$mod_SHIFT, X, exec, loginctl lock-session && sleep 2 && hyprctl dispatch dpms off && hyprlock"
          "$mod_SHIFT, Z, exec, loginctl lock-session && sleep 2 && hyprctl dispatch dpms off && systemctl suspend"
          "$mod_SHIFT, Y, exec, ${lib.getExe pkgs.chromium} --app=https://youtube.com"
          "$mod_SHIFT, M, exec, ${lib.getExe pkgs.chromium} --app=https://music.youtube.com"
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
          "$mod_SHIFT, v, togglesplit"
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

        bindm = [
          "$mod, mouse:272, resizewindow"
          "$mod, mouse:273, movewindow"
        ];

        binds = {
          allow_workspace_cycles = true;
        };

        cursor = {
          enable_hyprcursor = true;
        };

        debug = {
          disable_logs = false;
        };

        decoration = {
          dim_inactive = true;
          dim_strength = 0.35;
          rounding = 5;
        };

        dwindle = {
          pseudotile = true; # Master switch for pseudotiling
          preserve_split = true; # Essential for manual control
          smart_resizing = true; # Makes resizing tiles feel more natural
        };

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

        monitor = [
          "DP-1, 2560x1440@165, 90x0, 1"
          "DP-2, 3840x1600@144, 0x1440, 1"
          "DP-3, 2560x1440@120, 3840x480, 1, transform, 3"
        ];

        windowrulev2 = [
          "fullscreen,class:(^steam_app_\d+$)"
          "maximize, class:(Vivaldi-stable), initialTitle:(192.168.10.189_/)"
          "maximize, class:(chrome-music.youtube.com__-Default)"
          "maximize, class:(chrome-youtube.com__-Default)"
          "nodim, class:(^steam_app_\d+$)"
          "nodim, onworkspace:2"
          "nodim, onworkspace:8"
          "renderunfocused,class:(^steam_app_\d+$)"
          "size 90%, class:(chrome-music.youtube.com__-Default)"
          "size 90%, class:(chrome-youtube.com__-Default)"
          "workspace 10 silent, class:(steam)"
          "workspace 4 silent, class:(Bitwarden)"
          "workspace 4 silent, class:(Proton Mail)"
          "workspace 5 silent, class:(discord)"
          "workspace 6 silent, class:(obsidian)"
          "workspace 8 silent, class:(Vivaldi-stable), initialTitle:(192.168.10.189_/)"
          "workspace 8 silent, class:(chrome-music.youtube.com__-Default)"
          "workspace 8 silent, class:(chrome-youtube.com__-Default)"
          "workspace 9, class:(^steam_app_\d+$)"
        ];

        workspace = [
          "1, monitor:DP-2, gapsin:3, gapsout:3"
          "2, monitor:DP-2"
          "3, monitor:DP-2"
          "4, monitor:DP-2"
          "5, monitor:DP-3"
          "6, monitor:DP-3"
          "7, monitor:DP-3"
          "8, monitor:DP-1, gapsin:0, gapsout:0"
          "9, monitor:DP-1"
          "10, monitor:DP-1"
        ];
      };

      hyprlandConf = lib.thurs.toHyprconf {
        attrs = hyprlandSettings;
        importantPrefixes = [
          "$"
          "bezier"
          "source"
          "name"
          "output"
        ];
      };

    in
    {
      options.mine.desktop.hyprland = {
        enable = lib.mkEnableOption "Hyprland";
      };

      config = lib.mkIf cfg.enable {
        services.displayManager.sddm.wayland.enable = lib.mkIf config.mine.desktop.sddm.enable true;

        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
          withUWSM = true;
          systemd.setPath.enable = true;
        };

        environment = {
          variables = {
            HYPRLAND_CONFIG = "/etc/xdg/hypr/hyprland.conf";
          };
          sessionVariables = {
            NIXOS_OZONE_WL = "1";
            XDG_CURRENT_SESSION = "hyprland";
            XDG_SESSION_TYPE = "wayland";
            QT_QPA_PLATFORM = "wayland-egl";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
          };
        };

        environment.etc."xdg/hypr/hyprland.conf".text = hyprlandConf;

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-hyprland
          ];
          config.common.default = "*";
        };

        environment.systemPackages = with pkgs; [
          grim
          slurp
          wdisplays
          wl-clipboard
          xdg-utils
          adwaita-icon-theme
          hicolor-icon-theme
          hyprpicker
          swaynotificationcenter
          libnotify
        ];
      };
    };
}
