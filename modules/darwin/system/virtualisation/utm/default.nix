{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.virtualisation.utm;

in
{
  options.mine.system.virtualisation.utm = {
    enable = mkEnableOption "Enable UTM, Full featured system emulator and virtual machine host for iOS and macOS";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.utm
    ];
  };
}
