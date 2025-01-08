{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.boot.grub;

in
{
  options.mine.system.boot.grub = {
    enable = mkEnableOption "Enable Grub Bootloader";
  };

  config = mkIf cfg.enable {
    boot.loader.grub = {
      enable = true;
      useOSProber = false;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };
}
