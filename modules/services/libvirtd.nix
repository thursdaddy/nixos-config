_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.libvirtd;
    in
    {
      options.mine.services.libvirtd = {
        enable = lib.mkEnableOption "libvirtd";
      };

      config = lib.mkIf cfg.enable {
        users.users.${config.mine.user.base.name}.extraGroups = [ "libvirtd" ];

        environment.systemPackages = with pkgs; [
          virt-manager
        ];

        virtualisation.libvirtd = {
          enable = true;
          # allowedBridges = [ "br0" ];
          qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = true;
            swtpm.enable = true;
            # ovmf = {
            #   enable = true;
            #   packages = [
            #     (pkgs.OVMF.override {
            #       secureBoot = true;
            #       tpmSupport = true;
            #     }).fd
            #   ];
            # };
          };
        };
      };
    };
}
