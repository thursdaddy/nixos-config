{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      packages.hypridle-patched = pkgs.hypridle.overrideAttrs (oldAttrs: {
        src = pkgs.fetchFromGitHub {
          owner = "thursdaddy";
          repo = "hypridle";
          rev = "d0f7778c4e74d2fc81bd219789291b80ebe47a4a";
          hash = "sha256-aUGpceMR4LZX0aJL9VMXkEDxNTskoz09vGiTsPgHhxY=";
        };
        patches = (oldAttrs.patches or [ ]) ++ [
          ./hypridle-segfault-latest.patch
        ];
      });
    };
}
