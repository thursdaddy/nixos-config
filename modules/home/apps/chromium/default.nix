{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.apps.chromium;

in
{
  options.mine.apps.chromium = {
    enable = mkEnableOption "Enable chrome";
  };

  # browser builds not supported on darwin, use homebrew instead
  config = mkIf (cfg.enable && ! pkgs.stdenv.isDarwin) {
    home-manager.users.${user.name} = {
      home.sessionVariables.NIXOS_OZONE_WL = "1";

      programs.chromium = {
        enable = true;

        commandLineArgs = [
          "--ignore-gpu-blocklist"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          "--enable-features=VaapiVideoDecoder"
          "--enable-features=UseOzonePlatform"
          "--ozone-platform=wayland"
        ];
      };
    };
  };
}
