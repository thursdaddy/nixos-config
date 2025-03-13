{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.system.virtualisation.libvirtd;

in
{
  options.mine.system.virtualisation.libvirtd = {
    enable = mkEnableOption "libvirtd";
  };

  config = mkIf cfg.enable {
    users.users.${user.name}.extraGroups = mkIf user.enable [ "libvirtd" ];

    environment.systemPackages = with pkgs; [
      virt-manager
    ];

    virtualisation.libvirtd = {
      enable = true;
      allowedBridges = [ "br0" ];
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
  };
}
