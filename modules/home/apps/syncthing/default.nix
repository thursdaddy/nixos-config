{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.apps.syncthing;

in
{
  options.mine.apps.syncthing = {
    enable = mkEnableOption "Enable Syncthing";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      services.syncthing = {
        enable = true;
      };
    };
  };
}
