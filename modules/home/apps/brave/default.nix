{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.apps.brave;

in
{
  options.mine.apps.brave = {
    enable = mkEnableOption "Install Brave browser";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.brave = {
        enable = true;
      };
    };
  };
}
