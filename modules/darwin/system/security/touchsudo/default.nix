{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.security.touchsudo;

in
{
  options.mine.system.security.touchsudo = {
    enable = mkEnableOption "Enable sudo via Touch ID";
  };

  config = mkIf cfg.enable {
    # Add ability to use TouchID for sudo authentication
    security.pam.enableSudoTouchIdAuth = true;
    environment.systemPackages = [
      pkgs.pam-reattach
    ];
  };
}
