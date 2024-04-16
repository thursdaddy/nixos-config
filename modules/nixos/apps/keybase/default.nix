{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.keybase;

in
{
  options.mine.apps.keybase = {
    enable = mkEnableOption "keybase";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      keybase
      keybase-gui
    ];

    services.keybase.enable = true;
  };
}
