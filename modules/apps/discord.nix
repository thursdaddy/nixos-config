_: {
  flake.modules.generic.apps =
    { lib, ... }:
    {
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "discord"
        ];
    };
  flake.modules.homeManager.apps =
    { pkgs, lib, ... }:
    {
      home.packages = [ pkgs.unstable.discord ];
    };
}
