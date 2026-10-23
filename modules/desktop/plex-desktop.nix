_: {
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        jellyfin-desktop
        feishin
      ];
    };
}
