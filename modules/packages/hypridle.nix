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
          rev = "32e428cc9fa3da16f9871ce5f3128a3bbb4734ca";
          hash = "sha256-55LtUi7FIrVjyQOWcs/YPdqUbUuPfpQNm6EfJSvdPes=";
        };
        patches = (oldAttrs.patches or [ ]) ++ [
          ./hypridle-segfault-latest.patch
        ];
      });
    };
}
