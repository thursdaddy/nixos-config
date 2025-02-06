{ lib, config, pkgs, ... }:
let

  inherit (lib) mkIf;
  inherit (config.mine) user;
  cfg = config.mine.system.utils;

in
{
  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [ nixpkgs-fmt ];
    };
  };
}
