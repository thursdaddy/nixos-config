{ inputs, ... }:
let
  unstablePkgs = final: prev: {
    unstable = import inputs.unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  customPkgs = final: prev: {
    homelab-backup = inputs.self.packages.${final.stdenv.hostPlatform.system}.homelab-backup;
  };
in
{
  flake.modules.generic.base =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        customPkgs
        unstablePkgs
      ];
    };
}
