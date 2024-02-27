{ lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.hyprlock;
user = config.mine.nixos.user;

in {
  options.mine.home.hyprlock = {
    enable = mkOpt types.bool false "Enable hyprlock";
  };

  config = mkIf cfg.enable {

    home-manager.users.${user.name} = {
      imports = [
        inputs.hyprlock.homeManagerModules.hyprlock
      ];

      programs.hyprlock = {
        enable = true;
      };
    };

  };

}
