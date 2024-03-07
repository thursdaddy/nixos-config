{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.hyprland;
user = config.mine.nixos.user;

in {
  options.mine.home.hyprland = {
    enable = mkOpt types.bool false "Enable Hyprland";
  };

  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable {

      home-manager.users.${user.name} = {
        wayland.windowManager.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${pkgs.system}.hyprland;

          systemd = {
            enable = true;
            extraCommands = [
              "systemctl --user import-environment PATH"
              "systemctl --user restart xdg-desktop-portal.service"
              "systemctl --user stop hyprland-session.target"
              "systemctl --user start hyprland-session.target"
            ];
          };


          extraConfig = ''
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
            workspace = 8, monitor:DP-1
            workspace = 9, monitor:DP-1
            workspace = 0, monitor:DP-1
          '';

          settings = {
            "$mod" = "SUPER";
            bind =
              [
              "$mod, F, fullscreen"
              "$mod, Y, exec, ${pkgs.google-chrome}/share/google/chrome/chrome --app=https://youtube.com"
              "$mod, space, exec, fuzzel"
              "$mod_SHIFT, Q, killactive"
              "$mod_SHIFT, X, exec, hyprlock"
              "$mod, return, exec, alacritty"
              # Mouse Focus
              "$mod, h, movefocus, l"
              "$mod, l, movefocus, r"
              "$mod, k, movefocus, u"
              "$mod, j, movefocus, d"
              # Window Management
              "$mod_SHIFT, h, movewindow, l"
              "$mod_SHIFT, l, movewindow, r"
              "$mod_SHIFT, k, movewindow, u"
              "$mod_SHIFT, j, movewindow, d"
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
    };
  };

}
