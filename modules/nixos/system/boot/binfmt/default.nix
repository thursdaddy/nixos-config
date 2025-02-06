{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.boot.binfmt;

in
{
  options.mine.system.boot.binfmt = {
    enable = mkEnableOption "Enable binfmt emulation";
  };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
}
