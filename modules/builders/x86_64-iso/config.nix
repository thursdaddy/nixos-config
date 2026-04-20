_: {
  configurations.nixos.x86_64-iso.module =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
    in
    {
      imports = [
        (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
      ];

      config = {
        system.stateVersion = "25.11";

        isoImage.squashfsCompression = "gzip -Xcompression-level 1";
        security.sudo.enable = lib.mkForce false;
        services.openssh.settings.PermitRootLogin = lib.mkForce "no";

        mine = {
          base = {
            networking = {
              networkd = enabled;
              hostName = "iso";
            };
          };
        };
      };
    };
}
