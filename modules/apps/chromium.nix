_: {
  flake.modules.generic.apps =
    { lib, ... }:
    {
      options.mine.apps.chromium = {
        enable = lib.mkEnableOption "Enable Hyprpaper Home-Manager config";
      };
    };

  flake.modules.homeManager.apps =
    { lib, osConfig, ... }:
    let
      cfg = osConfig.mine.apps.chromium;
    in
    {
      config = lib.mkIf cfg.enable {
        home.sessionVariables.NIXOS_OZONE_WL = "1";

        programs.chromium = {
          enable = true;
          commandLineArgs = [
            "--ignore-gpu-blocklist"
            "--enable-gpu-rasterization"
            "--enable-zero-copy"
            "--canvas-oop-rasterization"
            "--enable-features=VaapiVideoDecoder"
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
          ];
        };
      };
    };
}
