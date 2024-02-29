{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.fuzzel;
user = config.mine.nixos.user;

in {
  options.mine.home.fuzzel = {
    enable = mkOpt types.bool false "Enable fuzzel";
  };

  config = mkIf cfg.enable {

    home-manager.users.${user.name} = {
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            font = "Hack:size=11";
            dpi-aware = "yes";
            lines = 3;
          };
          border = { width = 2; };
        };
      };
    };
  };

}
