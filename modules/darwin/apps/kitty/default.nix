{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.kitty;

in {
  config = mkIf cfg.enable {
    # TODO:
    # figure out how to get home-manager apps to show up in Spotlight / Dock
    # so I dont have to install via homebrew
    # homebrew.casks = [ "kitty" ];
    # system.defaults.dock.persistent-apps = {
  };
}
