{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.syncthing;
  inherit (config.mine) user;

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
