{ pkgs, lib, config, ... }:
with lib;
let

  cfg = config.mine.tools.keymapp;

in
{
  options.mine.tools.keymapp = {
    enable = mkEnableOption "Enable keymapp, ZSA keyboard flashing utility";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unstable.keymapp
    ];
    hardware.keyboard.zsa.enable = true;
  };
}
