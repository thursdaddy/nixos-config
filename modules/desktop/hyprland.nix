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

      toLua = lib.generators.toLua { multiline = false; };
      call = fn: args: "hl.${fn}(${toLua args})";
      bind = keys: dispatcher: "hl.bind(${toLua keys}, ${dispatcher})";
      exec = cmd: "hl.dsp.exec_cmd(${toLua cmd})";

      mod = "SUPER";

      settings = {
        animations.enabled = true;
        binds.allow_workspace_cycles = true;
        cursor.enable_hyprcursor = true;
        debug.disable_logs = false;

        decoration = {
          dim_inactive = true;
          dim_strength = 0.35;
          rounding = 5;
        };

        dwindle = {
          preserve_split = true; # Essential for manual control
          smart_resizing = true; # Makes resizing tiles feel more natural
        };

        general = {
          layout = "dwindle";
          gaps_in = 5;
          gaps_out = 5;
        };

        group = {
          col = {
            border_active = "0xffffffff";
            border_inactive = "0xff000000";
          };
          groupbar = {
            height = 14;
            font_size = 12;
            indicator_height = 2;
            text_color = "0xffffffff";
            col = {
              active = "0xff88c0d0";
              inactive = "0xff4c566a";
            };
          };
        };

        master.new_status = "master";

        misc = {
          allow_session_lock_restore = true;
          key_press_enables_dpms = true;
        };
      };

      curves = [
        ''hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })''
        ''hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })''
      ];

      animations = [
        {
          leaf = "windowsIn";
          speed = 5;
          bezier = "easeOutQuint";
          style = "slidefade";
        }
        {
          leaf = "windowsOut";
          speed = 3;
          bezier = "easeOutQuint";
          style = "popin 50%";
        }
        {
          leaf = "windowsMove";
          speed = 3;
          bezier = "easeOutQuint";
          style = "popin 50%";
        }
        {
          leaf = "workspaces";
          speed = 5;
          bezier = "overshot";
          style = "slidevert";
        }
        {
          leaf = "fade";
          speed = 5;
          bezier = "default";
        }
        {
          leaf = "border";
          speed = 20; # Slow border color fade
          bezier = "default";
        }
      ];

      monitors = [
        {
          output = "DP-1";
          mode = "2560x1440@165";
          position = "90x0";
          scale = 1;
        }
        {
          output = "DP-2";
          mode = "3840x1600@144";
          position = "0x1440";
          scale = 1;
        }
        {
          output = "DP-3";
          mode = "2560x1440@120";
          position = "3840x480";
          scale = 1;
          transform = 3;
        }
      ];

      monitorFallbacks = {
        "DP-3" = [
          "DP-2"
          "DP-1"
        ];
        "DP-2" = [
          "DP-1"
          "DP-3"
        ];
        "DP-1" = [
          "DP-2"
          "DP-3"
        ];
      };

      workspaceRules = [
        {
          workspace = "1";
          monitor = "DP-2";
          gaps_in = 3;
          gaps_out = 3;
        }
        {
          workspace = "2";
          monitor = "DP-2";
        }
        {
          workspace = "3";
          monitor = "DP-2";
        }
        {
          workspace = "4";
          monitor = "DP-2";
        }
        {
          workspace = "5";
          monitor = "DP-3";
        }
        {
          workspace = "6";
          monitor = "DP-3";
        }
        {
          workspace = "7";
          monitor = "DP-3";
        }
        {
          workspace = "8";
          monitor = "DP-1";
          gaps_in = 0;
          gaps_out = 0;
        }
        {
          workspace = "9";
          monitor = "DP-1";
        }
        {
          workspace = "10";
          monitor = "DP-1";
        }
      ];

      workspaceByClass = {
        steam = "10";
        Bitwarden = "4";
        proton-mail = "4";
        discord = "5";
        element-desktop = "5";
        "md.obsidian.Obsidian" = "6";
      };

      windowRules = [
        {
          match.class = "^steam_app_[0-9]+$";
          fullscreen = true;
          no_dim = true;
          render_unfocused = true;
          workspace = "9";
        }
        {
          match.workspace = "2";
          no_dim = true;
        }
        {
          match.workspace = "8";
          no_dim = true;
        }
      ]
      ++
        map
          (class: {
            match.class = class;
            maximize = true;
            size = "90% 90%";
            workspace = "8 silent";
          })
          [
            "chrome-music.youtube.com__-Default"
            "chrome-youtube.com__-Default"
            "org.jellyfin.JellyfinDesktop"
          ]
      ++ lib.mapAttrsToList (class: ws: {
        match.class = class;
        workspace = "${ws} silent";
      }) workspaceByClass;

      layerRules = [
        {
          match.namespace = "waybar";
          blur = true;
          ignore_alpha = 0.1;
        }
        {
          match.namespace = "swaync-control-center";
          blur = true;
          ignore_alpha = 0.1;
        }
        {
          match.namespace = "swaync-notification-window";
          blur = true;
          ignore_alpha = 0.1;
          no_anim = true;
        }
      ];

      binds = [
        (bind "${mod} + space" (exec "fuzzel"))
        (bind "${mod} + SHIFT + space" "hl.dsp.window.float()")
        (bind "${mod} + return" (exec "ghostty"))
        (bind "${mod} + SHIFT + return" "hl.dsp.exec_cmd(\"ghostty\", { float = true, no_anim = true })")
        (bind "${mod} + F" "hl.dsp.window.fullscreen()")
        (bind "${mod} + E" (exec "bemoji -c"))
        (bind "${mod} + G" (
          exec "grim -g \"$(slurp)\" \"${user.homeDir}/pictures/screenshots/$(date +'%F_%H-%M-%S_slurp')\""
        ))
        (bind "${mod} + SHIFT + B" (exec "vivaldi"))
        (bind "${mod} + SHIFT + D" (exec "discord"))
        (bind "${mod} + SHIFT + F" "hl.dsp.window.fullscreen({ mode = \"maximized\" })")
        (bind "${mod} + SHIFT + G" (exec "grim -g \"$(slurp)\" - | wl-copy"))
        (bind "${mod} + SHIFT + O" (exec "obsidian"))
        (bind "${mod} + SHIFT + P" (exec "${lib.getExe pkgs.jellyfin-desktop}"))
        (bind "${mod} + SHIFT + Q" "hl.dsp.window.close()")
        (bind "${mod} + SHIFT + X" (exec "loginctl lock-session"))
        (bind "${mod} + SHIFT + Z" (exec "systemctl suspend"))
        (bind "${mod} + SHIFT + Y" (exec "${lib.getExe pkgs.chromium} --app=https://youtube.com"))
        (bind "${mod} + SHIFT + M" (exec "${lib.getExe pkgs.chromium} --app=https://music.youtube.com"))
        (bind "${mod} + mouse:272" "hl.dsp.window.resize()")
        (bind "${mod} + mouse:273" "hl.dsp.window.drag()")
        # Workspace Switcher
        (bind "${mod} + TAB" "hl.dsp.focus({ workspace = \"previous\" })")
        (bind "${mod} + T" "hl.dsp.group.toggle()")
        (bind "${mod} + C" "hl.dsp.group.prev()")
        (bind "${mod} + V" "hl.dsp.group.next()")
        (bind "${mod} + SHIFT + V" "hl.dsp.layout(\"togglesplit\")")
      ]
      ++ lib.concatLists (
        lib.mapAttrsToList
          (key: direction: [
            (bind "${mod} + ${key}" "hl.dsp.focus({ direction = \"${direction}\" })")
            (bind "${mod} + SHIFT + ${key}" "hl.dsp.window.move({ direction = \"${direction}\", group_aware = true })")
          ])
          {
            H = "left";
            L = "right";
            K = "up";
            J = "down";
          }
      )
      ++ lib.concatMap (
        # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
        ws:
        let
          key = toString (lib.mod ws 10);
        in
        [
          (bind "${mod} + ${key}" "hl.dsp.focus({ workspace = ${toString ws} })")
          (bind "${mod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${toString ws} })")
        ]
      ) (lib.range 1 10);

      workspaceFallbackLua = ''
        do
          local base_workspace_rules = ${toLua workspaceRules}
          local monitor_fallbacks = ${toLua monitorFallbacks}
        ${builtins.readFile ./hyprland/workspace-fallback.lua}
        end
      '';

      hyprlandLua = lib.concatLines (
        [ (call "config" settings) ]
        ++ map (call "monitor") monitors
        ++ curves
        ++ map (a: call "animation" (a // { enabled = true; })) animations
        ++ [ workspaceFallbackLua ]
        ++ map (call "window_rule") windowRules
        ++ map (call "layer_rule") layerRules
        ++ binds
      );

    in
    {
      options.mine.desktop.hyprland = {
        enable = lib.mkEnableOption "Hyprland";
      };

      config = lib.mkIf cfg.enable {
        programs.hyprland = {
          enable = true;
          package = pkgs.unstable.hyprland;
          xwayland.enable = true;
          withUWSM = true;
          systemd.setPath.enable = true;
        };

        environment = {
          etc."xdg/hypr/hyprland.lua".text = hyprlandLua;
          sessionVariables = {
            NIXOS_OZONE_WL = "1";
            QT_QPA_PLATFORM = "wayland;xcb";
            XDG_CURRENT_DESKTOP = "Hyprland";
            XDG_SESSION_DESKTOP = "Hyprland";
            XDG_SESSION_TYPE = "wayland";
          };
          systemPackages = with pkgs; [
            grim
            slurp
            wdisplays
            wl-clipboard
            xdg-utils
            adwaita-icon-theme
            hicolor-icon-theme
            hyprpicker
          ];
          variables = {
            HYPRLAND_CONFIG = "/etc/xdg/hypr/hyprland.lua";
          };
        };

        # gtk.nix sets config.common, whose portals.conf would otherwise shadow
        # the hyprland-portals.conf shipped in the hyprland package
        xdg.portal.config.hyprland.default = [
          "hyprland"
          "gtk"
        ];
      };
    };
}
