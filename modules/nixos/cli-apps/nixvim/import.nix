{ lib, ... }:

# Credit: @infinisil
# https://github.com/Infinisil/system/blob/df9232c4b6cec57874e531c350157c37863b91a0/config/new-modules/default.nix

with lib;
let
    getDir = dir:
      mapAttrs (file: type: if type == "directory" then getDir "${dir}/${file}" else type)
      (builtins.readDir dir);

    files = dir:
      collect isString (mapAttrsRecursive (path: type: concatStringsSep "/" path)
      (getDir dir));

    getVimNix = dir:
      builtins.map(file: ./. + "/${file}")
      (builtins.filter (file: builtins.baseNameOf file == "vim.nix")
      (files dir));
in {

    imports = getVimNix ./.;
}
