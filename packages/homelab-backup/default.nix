{ pkgs, lib }:
let
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.docker
    ps.requests
  ]);
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
    # Copy the script sources into the store
    cp ${./backup.py} $out/bin/.homelab-backup
    cp ${./daily_report.py} $out/bin/.homelab-backup-report

    makeWrapper ${lib.getExe pythonEnv} $out/bin/homelab-backup \
      --add-flags "$out/bin/.homelab-backup" \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.rsync
          pkgs.openssh
          pkgs.gnutar
          pkgs.busybox
          pkgs.sudo
        ]
      }

    makeWrapper ${lib.getExe pythonEnv} $out/bin/homelab-backup-report \
      --add-flags "$out/bin/.homelab-backup-report" \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.curl
          pkgs.busybox
        ]
      }
  '';

  meta = {
    description = "Python-based backup utility and report generator for homelab backups";
    mainProgram = "homelab-backup";
  };
}
