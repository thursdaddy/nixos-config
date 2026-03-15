{ inputs, ... }:
let
  unstablePkgs = final: prev: {
    unstable = import inputs.unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
in
{
  flake.modules.generic.base =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ unstablePkgs ];
    };
}
