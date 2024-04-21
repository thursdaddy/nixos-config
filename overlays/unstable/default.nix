{ inputs, ... }:
let
  unstablePkgs = final: prev: {
    unstable = import inputs.unstable {
      system = "${prev.system}";
      config.allowUnfree = true;
    };
  };
in
{
  nixpkgs.overlays = [ unstablePkgs ];
}
