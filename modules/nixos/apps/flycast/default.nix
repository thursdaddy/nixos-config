{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.flycast;

in
{
  options.mine.apps.flycast = {
    enable = mkEnableOption "Install Flycast - Dreamcast Emulator";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      flycast
    ];

    # microsoft wireless controller adapter
    hardware.xone.enable = true;
  };
}
