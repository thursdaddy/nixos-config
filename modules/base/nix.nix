{ inputs, ... }:
{
  flake.modules.generic.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (config.mine.base) user;
      cfg = config.mine.base.nix;
      isDarwin = pkgs.stdenv.isDarwin;
    in
    {
      options.mine.base.nix = {
        substituters.enable = lib.mkOption {
          description = "Enable local attic.thurs.pw substituter";
          type = lib.types.bool;
          default = true;
        };
        ghToken.enable = lib.mkEnableOption "Enable github user token";
      };

      config = {
        nix = {
          extraOptions = ''
            warn-dirty = false
            ${if cfg.ghToken.enable then "!include ${config.sops.secrets."github/TOKEN".path}" else ""}
          '';

          gc = {
            automatic = true;
            options = "--delete-older-than 14d";
          }
          // (
            if isDarwin then
              {
                interval = {
                  Weekday = 0;
                  Hour = 0;
                  Minute = 0;
                };
              }
            else
              {
                dates = "weekly";
              }
          );

          nixPath = [ "/etc/nix/path" ];

          optimise.automatic = true;

          registry.nixpkgs.flake = inputs.nixpkgs;

          settings = {
            download-buffer-size = 524288000;
            experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
          // lib.optionalAttrs (cfg.substituters.enable) {
            substituters = [ "https://attic.thurs.pw/local?priority=1" ];
            trusted-public-keys = [
              "local:itXoM4f8cbcC/kFOdbmj/P1mY5C9OICa+ociYA40j4E="
            ];
          };
        };

        environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;

        documentation.man = {
          enable = true;
        }
        // lib.optionalAttrs (!isDarwin) {
          generateCaches = lib.mkForce false;
        };

        sops.secrets."github/TOKEN" = lib.mkIf cfg.ghToken.enable {
          mode = "0440";
          owner = "${user.name}";
        };
      };
    };
}
