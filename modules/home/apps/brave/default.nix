{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.brave;
  inherit (config.mine) user;

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
