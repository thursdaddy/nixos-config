{ lib, config,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.chrome;
user = config.mine.user;

in {
  options.mine.home.chrome = {
    enable = mkOpt types.bool false "Enable chrome";
  };

  config = mkIf cfg.enable {

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
