_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "steam" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Steam.app" ];
  };
}
