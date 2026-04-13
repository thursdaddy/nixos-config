_: {
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.nautilus
      ];
    };
}
