_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      programs.firefox.enable = true;
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "firefox" ];
  };
}
