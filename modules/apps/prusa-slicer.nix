_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.prusa-slicer
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "prusaslicer" ];

    system.defaults.dock.persistent-apps = [ "/Applications/PrusaSlicer.app/" ];
  };
}
