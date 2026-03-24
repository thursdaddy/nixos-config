_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.unstable.vivaldi
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "vivaldi" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Vivaldi.app" ];
  };
}
