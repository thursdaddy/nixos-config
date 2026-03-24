_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.vlc
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "vlc" ];
  };
}
