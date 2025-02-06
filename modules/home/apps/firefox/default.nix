{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.apps.firefox;

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
