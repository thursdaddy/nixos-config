{ inputs, ... }:
let
  unstablePkgs = final: prev: {
    unstable = import inputs.unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
in
{
  nixpkgs.overlays = [ unstablePkgs ];
}
