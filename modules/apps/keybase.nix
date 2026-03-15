_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        keybase
        keybase-gui
      ];

      services.keybase.enable = true;
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "keybase" ];
  };
}
