{ lib, config, ... }:
with lib;
let

  cfg = config.mine.tools.direnv;
  user = config.mine.user;

  in {
    options.mine.tools.direnv = {
      enable = mkEnableOption "Enable direnv";
    };

    config = mkIf cfg.enable {
      home-manager.users.${user.name} = {
        programs.direnv = {
          enable = true;
        };
      };

    };
  }
