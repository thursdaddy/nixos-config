{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.system.services.bluetooth;

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
