{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.virtualisation.libvirtd;
  user = config.mine.user;

in
{
  options.mine.system.virtualisation.libvirtd = {
    enable = mkEnableOption "libvirtd";
  };

  config = lib.mkIf cfg.enable {
    users.users.${user.name}.extraGroups = mkIf user.enable [ "libvirtd" ];

    environment.systemPackages = with pkgs; [
      virt-manager
    ];

    virtualisation.libvirtd = {
      enable = true;
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
