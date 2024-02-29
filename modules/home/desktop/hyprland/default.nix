{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.hyprland;
user = config.mine.nixos.user;

in {
  options.mine.home.hyprland = {
    enable = mkOpt types.bool false "Enable Hyprland";
  };

  config = mkIf cfg.enable {

      services.xserver = {
        enable = true;
      };

      services.xserver.displayManager.sddm = {
        enable = true;
      };

      home-manager.users.${user.name} = {
        wayland.windowManager.hyprland = {
          enable = true;

          systemd = {
            enable = true;
          };

          settings = {
            "$mod" = "SUPER";
            bind =
              [
              "$mod_SHIFT, Q, killactive"
                "$mod, F, exec, firefox"
                "$mod, return, exec, alacritty"
                "$mod_SHIFT, X, exec, hyprlock"
                ", Print, exec, grimblast copy area"
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
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                  ]
                  )
                10)
               );
        };
      };
    };
  };

}
