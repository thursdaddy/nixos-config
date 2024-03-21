{ lib, config, ... }:
with lib;
let

  cfg = config.mine.home.brave;
  user = config.mine.user;

in {
  options.mine.home.brave = {
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
