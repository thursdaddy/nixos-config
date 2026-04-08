{ lib }:
let
  files = lib.filterAttrs (name: type: name != "default.nix" && lib.hasSuffix ".nix" name) (
    builtins.readDir ./.
  );

  filePaths = lib.mapAttrsToList (name: type: ./. + "/${name}") files;

  functions = lib.foldl' (acc: path: acc // (import path { inherit lib; })) { } filePaths;
in
functions
