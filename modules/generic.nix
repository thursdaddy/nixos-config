{ inputs, lib, ... }:
{
  # import "generic" modules when a system based module is imported
  flake.modules =
    let
      moduleNames = [
        "base"
        "dev"
        "apps"
        "desktop"
      ];
      systems = [
        "nixos"
        "darwin"
      ];
    in
    lib.genAttrs systems (
      sys:
      lib.genAttrs moduleNames (name: {
        imports = [ inputs.self.modules.generic.${name} ];
      })
    );
}
