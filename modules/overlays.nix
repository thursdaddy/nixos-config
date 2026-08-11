{ inputs, ... }:
let
  unstablePkgs = final: prev: {
    unstable = import inputs.unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  customPkgs = final: prev: {
    darwinGit = final.callPackage ../packages/darwinGit { pkgs = final; };
    gotify-alert = final.callPackage ../packages/gotify-alert { pkgs = final; };
    hass-gotify = final.home-assistant.python3Packages.callPackage ../packages/hass-gotify { };
    homelab-backup = final.callPackage ../packages/homelab-backup { pkgs = final; };
    hypridle-patched = final.callPackage ../packages/hypridle { pkgs = final; };
    octoprint312 = final.callPackage ../packages/octoprint312 { pkgs = final; };
    siomon = final.callPackage ../packages/siomon { pkgs = final; };
    wallpapers = final.callPackage ../packages/wallpapers { pkgs = final; };
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

    # Disable flaky timing tests in tenacity and nbmake which frequently fail on slower hardware (like the Raspberry Pi)
    pythonPackagesExtensions =
      (prev.pythonPackagesExtensions or [ ])
      ++ prev.lib.optionals (prev.stdenv.hostPlatform.isAarch64) [
        (python-final: python-prev: {
          tenacity = python-prev.tenacity.overridePythonAttrs (oldAttrs: {
            doCheck = false;
            doInstallCheck = false;
          });
          nbmake = python-prev.nbmake.overridePythonAttrs (oldAttrs: {
            doCheck = false;
            doInstallCheck = false;
            propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [ python-final.pytest ];
          });
          uuid6 = python-prev.uuid6.overridePythonAttrs (oldAttrs: {
            doCheck = false;
            doInstallCheck = false;
          });
          paho-mqtt = python-prev.paho-mqtt.overridePythonAttrs (oldAttrs: {
            doCheck = false;
            doInstallCheck = false;
          });
        })
        (python-final: python-prev:
          if python-prev.python.pythonVersion == "3.12" then {
            pytestCheckHook = python-final.toPythonModule (final.makeSetupHook {
              name = "pytest-check-hook";
              propagatedBuildInputs = [ python-final.pytest ];
            } (final.writeText "empty-hook.sh" "pytestCheckPhase() { :; }"));

            pytest7CheckHook = python-final.pytestCheckHook;
            pytest8_3CheckHook = python-final.pytestCheckHook;

            apsw = python-prev.apsw.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            peewee = python-prev.peewee.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            sentry-sdk = python-prev.sentry-sdk.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            pympler = python-prev.pympler.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            zeroconf = python-prev.zeroconf.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            pyrsistent = python-prev.pyrsistent.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            sarge = python-prev.sarge.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            aiohttp = python-prev.aiohttp.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            pytest-benchmark = python-prev.pytest-benchmark.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            limits = python-prev.limits.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            flask-limiter = python-prev.flask-limiter.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            jaraco-test = python-prev.jaraco-test.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            importlib-resources = python-prev.importlib-resources.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
            nbmake = python-prev.nbmake.overridePythonAttrs (old: { doCheck = false; doInstallCheck = false; dontUsePytestCheck = true; });
          } else {})
      ];
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
