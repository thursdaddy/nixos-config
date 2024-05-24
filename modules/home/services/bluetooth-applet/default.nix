{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.services.bluetooth;
  user = config.mine.user;

in
{
  options.mine.system.services.bluetooth = {
    applet = mkEnableOption "Enable bluetooth applet";
  };

  config = mkIf cfg.applet {
    home-manager.users.${user.name} = {
      services.blueman-applet.enable = true;
    };
  };
}
