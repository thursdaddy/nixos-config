{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  nodejs,
  pnpm_9,
}:
let
  pname = "upsnap";
  version = "5.0.3";
  src = fetchFromGitHub {
    owner = "seriousm4x";
    repo = "UpSnap";
    rev = "de66c391911488d8c5c1a193cbf631e58a317daf";
    hash = "sha256-euGAMyG3ysKr0WLrd9P6t+/gAdWRvi3RJYSTkWS18Os=";
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
      hash = "sha256-kHFqSNdpSbGTbX4Fqcj6zNlWOIMhHvFF+DXMWCE0rkc=";
    };

    sourceRoot = "${finalAttrs.src.name}/frontend";

    buildPhase = ''
      runHook preBuild

      PUBLIC_VERSION=${version} pnpm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -r ./build $out

      runHook postInstall
    '';

    meta = with lib; {
      description = "One-Click Device Wake-Up Dashboard";
      homepage = "https://github.com/seriousm4x/UpSnap";
      license = licenses.mit; # Replace with the actual license
      maintainers = with maintainers; [ ]; # Add maintainers if applicable
    };
  });

  goMod = buildGoModule {
    inherit pname version src;
    vendorHash = "sha256-HPrzXzHjaaYzABP5u+gzbgPHIkuplkazepvF9Q5M8NU=";
    modRoot = "./backend";
    doCheck = false;
  };

in
goMod.overrideAttrs (oldAttrs: {
  preBuild = ''
    cp -r ${frontend}/* ./pb_public
  '';

  ldflags = [
    "-s -w -X github.com/seriousm4x/upsnap/pb.Version=${version}"
  ];

  meta = with lib; {
    description = "One-Click Device Wake-Up Dashboard";
    homepage = "https://github.com/seriousm4x/UpSnap";
    license = licenses.mit; # Replace with the actual license
    maintainers = with maintainers; [ ]; # Add maintainers if applicable
  };
})
