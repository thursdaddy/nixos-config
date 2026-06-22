{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = {
        darwinGit = pkgs.callPackage ../../packages/darwinGit { };
        siomon = pkgs.callPackage ../../packages/siomon { };
        wallpapers = pkgs.callPackage ../../packages/wallpapers { };
      } // lib.optionalAttrs pkgs.stdenv.isLinux {
        gotify-alert = pkgs.callPackage ../../packages/gotify-alert { };
        hass-gotify = pkgs.home-assistant.python.pkgs.callPackage ../../packages/hass-gotify { };
        homelab-backup = pkgs.callPackage ../../packages/homelab-backup { };
        hypridle-patched = pkgs.callPackage ../../packages/hypridle { };
        octoprint312 = pkgs.callPackage ../../packages/octoprint312 { };
      };
    };
}
