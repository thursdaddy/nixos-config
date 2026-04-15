{ inputs, ... }:
let
  unstablePkgs = final: prev: {
    unstable = import inputs.unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  customPkgs = final: prev: {
    homelab-backup = inputs.self.packages.${final.stdenv.hostPlatform.system}.homelab-backup;
    input-remapper = prev.input-remapper.overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        # Swap the imports and exception names directly
        sed -i 's/import pkg_resources/import importlib.metadata/g' inputremapper/logging/logger.py inputremapper/configs/data.py
        sed -i 's/pkg_resources\.DistributionNotFound/importlib.metadata.PackageNotFoundError/g' inputremapper/logging/logger.py inputremapper/configs/data.py

        # Catch get_distribution('...'), get_distribution("..."), or require('...')[0]
        sed -i -E 's/pkg_resources\.(get_distribution|require)\([^)]+\)(\[0\])?\.version/importlib.metadata.version("input-remapper")/g' inputremapper/logging/logger.py inputremapper/configs/data.py
      '';

      # Filter out setuptools, but explicitly append packaging
      propagatedBuildInputs =
        prev.lib.filter (p: (p.pname or "") != "setuptools") (oldAttrs.propagatedBuildInputs or [ ])
        ++ [ prev.python3Packages.packaging ];
    });
  };

in
{
  flake.modules.generic.base =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        customPkgs
        unstablePkgs
      ];
    };
}
