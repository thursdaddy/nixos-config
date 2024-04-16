{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.system.nix.daemon;

in
{
  options.mine.system.nix.daemon = {
    enable = mkOpt types.bool true "Enable Nix Daemon";
  };

  config = mkIf cfg.enable {
    services.nix-daemon.enable = true;
  };
}
