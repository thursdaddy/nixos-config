{
  pkgs,
  lib,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.keymapp;

in
{
  options.mine.apps.keymapp = {
    enable = mkEnableOption "Enable keymapp, ZSA keyboard flashing utility";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unstable.keymapp
    ];
    hardware.keyboard.zsa.enable = true;
  };
}
