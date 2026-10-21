_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.unstable.signal-desktop
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "signal" ];
  };
}
