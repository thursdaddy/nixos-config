_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.vivaldi
        pkgs.vivaldi-ffmpeg-codecs
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "vivaldi" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Vivaldi.app" ];
  };
}
