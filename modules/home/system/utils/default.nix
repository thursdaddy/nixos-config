{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.utils;
  user = config.mine.user;

in {
  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = [ pkgs.nixpkgs-fmt ];
    };
  };
}
