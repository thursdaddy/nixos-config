{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.firefox;
  inherit (config.mine) user;

in
{
  options.mine.apps.firefox = {
    enable = mkEnableOption "Enable Firefox";
  };

  config = mkIf (cfg.enable && ! pkgs.stdenv.isDarwin) {
    home-manager.users.${user.name} = {
      programs.firefox = {
        enable = true;
      };

      home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
    };
  };

}
