{ inputs, ... }:
{
  configurations.nixos.proxbox1.module =
    { config, ... }:
    {
      imports = [ inputs.proxmox-nixos.nixosModules.proxmox-ve ];

      nixpkgs.overlays = [
        inputs.proxmox-nixos.overlays.x86_64-linux
      ];

      services.proxmox-ve = {
        enable = true;
        ipAddress = config.mine.base.networking.meta.hostIp;
      };
    };
}
