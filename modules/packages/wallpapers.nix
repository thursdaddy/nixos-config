{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      wallpaperPkg = pkgs.runCommand "wallpapers" { } ''
        mkdir -p $out
        cp -rf ${../../assets/wallpapers}/* $out/
      '';
    in
    {
      packages = {
        wallpapers = wallpaperPkg;
      };
    };
}
