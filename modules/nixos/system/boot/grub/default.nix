{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.boot.grub;

in {
  options.mine.system.boot.grub = {
    enable = mkEnableOption "Enable Grub Bootloader";
  };

  config = mkIf cfg.enable {
    boot.loader.grub.enable = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.grub.device = "nodev";
  };
}
