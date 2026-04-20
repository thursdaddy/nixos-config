_: {
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.supersonic-wayland
      ];
    };
}
