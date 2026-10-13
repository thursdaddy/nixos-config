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
        nixpkgs.config.permittedInsecurePackages = [
          "docker-28.5.2"
          "electron-39.8.10"
          "python3.12-ecdsa-0.19.1"
        ];
        nix = {
          distributedBuilds = true;
          buildMachines =
            (lib.optional (config.networking.hostName != "c137") {
              hostName = "c137";
              systems = [
                "x86_64-linux"
                "i686-linux"
                "aarch64-linux"
              ];
              maxJobs = 16;
              speedFactor = 20;
              sshUser = "${user.name}";
              supportedFeatures = [
                "nixos-test"
                "benchmark"
                "big-parallel"
                "kvm"
              ];
            })
            ++ (lib.optional (config.networking.hostName != "wormhole") {
              hostName = "wormhole";
              systems = [
                "x86_64-linux"
                "i686-linux"
                "aarch64-linux"
              ];
              maxJobs = 8;
              speedFactor = 10;
              sshUser = "${user.name}";
              supportedFeatures = [
                "nixos-test"
                "benchmark"
                "big-parallel"
                "kvm"
              ];
            })
            ++ (lib.optional isDarwin {
              hostName = "linux-builder";
              systems = [
                "aarch64-linux"
                "x86_64-linux"
              ];
              maxJobs = 4;
              speedFactor = 1;
              supportedFeatures = [ "kvm" ];
            });

          extraOptions = ''
            warn-dirty = false
            builders-use-substitutes = true
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
            substituters = [
              "https://celler.thurs.pw/cache?priority=1"
            ];
            trusted-public-keys = [
              "cache:Vf8V3TBE6VNUYg4Rh15l/fDzIpzRmevaJRBKWBaKK6I="
            ];
          };
        };

        environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;

        documentation.man = {
          enable = true;
        }
        // lib.optionalAttrs (!isDarwin) {
          cache.enable = lib.mkForce false;
        };

        sops.secrets."github/TOKEN" = lib.mkIf cfg.ghToken.enable {
          mode = "0440";
          owner = "${user.name}";
        };
      };
    };
}
