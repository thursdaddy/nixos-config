{ lib, config, ... }:
with lib;
let

  cfg = config.mine.services.flameshot;
  user = config.mine.user;

in
{
  options.mine.services.flameshot = {
    enable = mkEnableOption "Enable Flameshot screenshot tool";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      # stable build does not fully support hyprland, yet
      services.flameshot.enable = true;
    };
  };
}
