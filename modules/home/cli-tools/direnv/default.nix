{ lib, config, ... }:
with lib;
let

  cfg = config.mine.cli-tools.direnv;
  inherit (config.mine) user;

in
{
  options.mine.cli-tools.direnv = {
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
