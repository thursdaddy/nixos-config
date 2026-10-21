_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.unstable.antigravity-ide
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "antigravity" ];
  };
}
