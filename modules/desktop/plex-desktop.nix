_: {
  flake.modules.nixos.desktop =
    { lib, pkgs, ... }:
    {
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "plex-desktop"
        ];

      environment.systemPackages = with pkgs; [
        plex-desktop
      ];
    };
}
