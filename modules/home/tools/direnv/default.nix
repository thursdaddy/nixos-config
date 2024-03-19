{ lib, config, ... }:
with lib;
let

  cfg = config.mine.home.direnv;
  user = config.mine.nixos.user;

  in {
    options.mine.home.direnv = {
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
