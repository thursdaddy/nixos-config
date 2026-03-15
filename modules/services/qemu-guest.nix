_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      modulesPath,
      ...
    }:
    let
      cfg = config.mine.services.qemu-guest;
    in
    {
      options.mine.services.qemu-guest = {
        enable = lib.mkEnableOption "QEMU Guest for Proxmox Helper Daemon";
      };

      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      config = lib.mkIf cfg.enable {
        services.qemuGuest.enable = true;
      };
    };
}
