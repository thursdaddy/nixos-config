{
  pkgs,
  lib,
  go,
  fetchFromGitHub,
  buildGoModule,
  ...
}:

let
  pname = "grafana-ntfy";
  version = "0.8.0";
  src = fetchFromGitHub {
    owner = "academo";
    repo = "grafana-alerting-ntfy-webhook-integration";
    rev = "454271e4a9f24f57edfe6367a8e0b5e1299f6999";
    hash = "sha256-WOr4g5CceUDnCVPaRZcF5o3srVMApAXlnQDH7IS5XeQ=";
  };

  goMod = buildGoModule {
    inherit pname version src;
    vendorHash = "sha256-usg5vOOMYyPiKj6S9ZOopPOigYcY04vqMF8j9NWXC/M=";

    postInstall = ''
      mv $out/bin/pkg $out/bin/grafana-ntfy
    '';
  };
in
goMod
