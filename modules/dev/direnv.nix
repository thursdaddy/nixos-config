_: {
  flake.modules.generic.dev =
    { pkgs, ... }:
    {
      programs.direnv = {
        enable = true;
        nix-direnv = {
          enable = true;
          package = pkgs.nix-direnv;
        };
      };
    };
}
