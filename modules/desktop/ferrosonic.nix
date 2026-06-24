{ inputs, ... }: {
  flake.modules.generic.desktop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.mine.desktop.ferrosonic;
      
      ferrosonic = pkgs.rustPlatform.buildRustPackage rec {
        pname = "ferrosonic";
        version = "0.5.0";

        src = pkgs.fetchFromGitHub {
          owner = "jaidaken";
          repo = "ferrosonic";
          rev = "v${version}";
          hash = "sha256-dk01ewFMqkrqkQQ5MAiIdNk4Mueuuco04VxtgPOoYYo=";
        };

        cargoHash = "sha256-0/1DNMwsFOGqTu9ivJoNQJh8bUf1vaJ9JawDsQ0O25A=";
        
        doCheck = false; # Fails in Nix build sandbox due to mpv socket path
        
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl ];
      };
      
    in
    {
      options.mine.desktop.ferrosonic = {
        enable = lib.mkOption {
          description = "Ferrosonic Terminal Music Player";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          ferrosonic
          pkgs.mpv
        ];
      };
    };
}
