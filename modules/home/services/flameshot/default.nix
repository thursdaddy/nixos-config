{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.services.flameshot;

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
