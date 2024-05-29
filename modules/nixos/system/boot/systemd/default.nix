{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.boot.systemd;

in
{
  options.mine.system.boot.systemd = {
    enable = mkEnableOption "Enable systemd bootloader";
  };

  config = mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.consoleMode = "auto";
  };
}
