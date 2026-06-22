{ pkgs }:
pkgs.runCommand "wallpapers" { } ''
  mkdir -p $out
  cp -rf ${../../assets/wallpapers}/* $out/
''
