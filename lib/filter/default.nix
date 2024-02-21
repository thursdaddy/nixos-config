{ lib, ... }:

with lib; rec {

    getDir = dir:
      mapAttrs (file: type: if type == "directory" then getDir "${dir}/${file}" else type)
      (builtins.readDir dir);

    files = dir:
      collect isString (mapAttrsRecursive (path: type: concatStringsSep "/" path)
      (getDir dir));

    getDefaultNix = dir:
      builtins.map(file: ./. + "${file}")
      (builtins.filter (file: builtins.baseNameOf file == "default.nix")
      (files dir));
    #   ^ ^ ^
    #  you might just have to not call this in order to use it in the lib ^^

}
