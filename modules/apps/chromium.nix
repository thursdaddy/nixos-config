_: {
  flake.modules.nixos.apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.apps.chromium;

      myChromium = pkgs.symlinkJoin {
        name = "chromium";
        paths = [ pkgs.chromium ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/chromium \
            --add-flags "--ignore-gpu-blocklist" \
            --add-flags "--enable-gpu-rasterization" \
            --add-flags "--enable-zero-copy" \
            --add-flags "--canvas-oop-rasterization" \
            --add-flags "--enable-features=VaapiVideoDecoder,UseOzonePlatform" \
            --add-flags "--ozone-platform=wayland" \
            --add-flags "--force-dark-mode"
        '';
      };
    in
    {
      options.mine.apps.chromium = {
        enable = lib.mkEnableOption "Enable Home-Manager Chromium";
      };

      config = lib.mkIf cfg.enable {
        environment = {
          sessionVariables = {
            NIXOS_OZONE_WL = "1";
          };
          systemPackages = [ myChromium ];
        };

        programs.chromium = {
          enable = true;
          extensions = [
            "cfhdojbkjhnklbpkdaibdccddilifddb"
            "eimadpbcbfnmbkopoojfekhnkhdbieeh"
          ];
          extraOpts = {
            "BrowserSignin" = 0;
            "PasswordManagerEnabled" = false;
            "3rdparty" = {
              "extensions" = {
                "eimadpbcbfnmbkopoojfekhnkhdbieeh" = {
                  "automation" = {
                    "enabled" = true;
                    "mode" = "system"; # Follow your system's dark/light theme
                  };
                  "brightness" = 100;
                  "contrast" = 100;
                  "engine" = "dynamicTheme"; # The best quality rendering engine
                };
              };
            };
          };
        };
      };
    };
}
