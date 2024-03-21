{ lib, config, ... }:
with lib;
let

  cfg = config.mine.services.bluetooth;
  user = config.mine.user;

in {
  options.mine.services.bluetooth = {
    enable = mkEnableOption "Enable bluetooth";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      services.blueman-applet.enable = true;
    };
  };
}
