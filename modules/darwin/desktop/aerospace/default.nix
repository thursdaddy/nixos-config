{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.desktop.aerospace;

in
{
  options.mine.desktop.aerospace = {
    enable = mkEnableOption "aerospace";
  };

  config = mkIf cfg.enable {
    services = {
      aerospace = {
        enable = true;
        settings = {
          enable-normalization-flatten-containers = false;
          enable-normalization-opposite-orientation-for-nested-containers = false;

          mode.main.binding = {
            "alt-f" = "fullscreen";
            "alt-s" = "layout v_accordion";
            "alt-w" = "layout h_accordion";
            "alt-e" = "layout tiles horizontal vertical";

            "alt-1" = "workspace 1";
            "alt-2" = "workspace 2";
            "alt-3" = "workspace 3";
            "alt-4" = "workspace 4";
            "alt-5" = "workspace 5";
            "alt-6" = "workspace 6";
            "alt-7" = "workspace 7";
            "alt-8" = "workspace 8";
            "alt-9" = "workspace 9";
            "alt-0" = "workspace 10";
            "alt-shift-1" = "move-node-to-workspace 1";
            "alt-shift-2" = "move-node-to-workspace 2";
            "alt-shift-3" = "move-node-to-workspace 3";
            "alt-shift-4" = "move-node-to-workspace 4";
            "alt-shift-5" = "move-node-to-workspace 5";
            "alt-shift-6" = "move-node-to-workspace 6";
            "alt-shift-7" = "move-node-to-workspace 7";
            "alt-shift-8" = "move-node-to-workspace 8";
            "alt-shift-9" = "move-node-to-workspace 9";
            "alt-shift-0" = "move-node-to-workspace 10";

            "alt-shift-h" = "move left";
            "alt-shift-j" = "move down";
            "alt-shift-k" = "move up";
            "alt-shift-l" = "move right";

            "alt-h" = "split horizontal";
            "alt-v" = "split vertical";
            "alt-b" = "fullscreen";
          };
        };
      };
    };
  };
}
