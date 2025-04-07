{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.qemu-guest;
in
{
  options.mine.services.qemu-guest = {
    enable = mkEnableOption "QEMU Guest for Proxmox";
  };

  config = mkIf cfg.enable {
    services.qemuGuest.enable = true;
  };
}
