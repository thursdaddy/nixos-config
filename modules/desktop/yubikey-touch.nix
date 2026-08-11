_: {
  flake.modules.nixos.desktop =
    {
      pkgs,
      ...
    }:
    {
      programs.yubikey-touch-detector = {
        enable = true;
        libnotify = true;
      };

      environment.systemPackages = with pkgs; [
        yubikey-touch-detector
        pinentry-gnome3
        libnotify
      ];
    };

  flake.modules.darwin.desktop = {
    homebrew = {
      brews = [
        "pinentry-mac"
      ];
    };
  };
}
