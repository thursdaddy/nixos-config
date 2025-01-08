{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.utils;
  inherit (config.mine) user;

in
{
  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [ nixpkgs-fmt ];
    };
  };
}
