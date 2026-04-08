{
  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      packages.homelab-backup =
        let
          pythonEnv = pkgs.python3.withPackages (ps: [ ps.docker ]);
        in
        pkgs.stdenv.mkDerivation {
          pname = "homelab-backup";
          version = "0.0.1";

          phases = [
            "installPhase"
            "fixupPhase"
          ];

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin
            # Copy the script source into the store
            cp ${./backup.py} $out/bin/.homelab-backup

            makeWrapper ${lib.getExe pythonEnv} $out/bin/homelab-backup \
              --add-flags "$out/bin/.homelab-backup" \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.gnutar
                  pkgs.busybox
                ]
              }
          '';

          meta = {
            description = "Python-based backup utility for homelab backups";
            mainProgram = "homelab-backup";
          };
        };
    };
}
