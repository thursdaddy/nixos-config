{ lib, stdenv, buildGoModule, fetchFromGitHub, nodejs, pnpm_9, pkgs, unstable }:
let
  latest = unstable.legacyPackages.${pkgs.system};

  pname = "upsnap";
  version = "4.6.0";

  src = fetchFromGitHub {
    owner = "seriousm4x";
    repo = "UpSnap";
    rev = "65be53bd3c32c2505847f557dbf0bc8bfd31ae81";
    hash = "sha256-9/YRFMp3lIk/n39O9G16dCwZ11jzXxtPLjm9ZFwIob0=";
  };

  frontend = stdenv.mkDerivation (finalAttrs: {
    inherit pname version src;

    nativeBuildInputs = [
      nodejs
      pnpm_9.configHook
    ];

    pnpmDeps = pnpm_9.fetchDeps {
      inherit (finalAttrs) pname version src;
      sourceRoot = "${finalAttrs.src.name}/frontend";
      hash = "sha256-2mG+V/6rzxUHi3UJPNpqhbhcFirlp3q0EabDCgJBqHk";
    };

    sourceRoot = "${finalAttrs.src.name}/frontend";

    buildPhase = ''
      pnpm run build
    '';

    installPhase = ''
      cp -r ./build $out
    '';

    meta = with lib; {
      description = "One-Click Device Wake-Up Dashboard";
      homepage = "https://github.com/seriousm4x/UpSnap";
      license = licenses.mit; # Replace with the actual license
      maintainers = with maintainers; [ ]; # Add maintainers if applicable
    };
  });

in
buildGoModule.override { go = latest.go; } {
  inherit pname version src;
  vendorHash = "sha256-HPrzXzHjaaYzABP5u+gzbgPHIkuplkazepvF9Q5M8NU=";

  preBuild = ''
    cp -r ${frontend}/* ./pb_public
  '';

  modRoot = "./backend";

  doCheck = false;

  meta = with lib; {
    description = "One-Click Device Wake-Up Dashboard";
    homepage = "https://github.com/seriousm4x/UpSnap";
    license = licenses.mit; # Replace with the actual license
    maintainers = with maintainers; [ ]; # Add maintainers if applicable
  };
}
