_: {
  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    {
      packages.siomon = pkgs.rustPlatform.buildRustPackage {
        pname = "siomon";
        version = "0.1.2";

        src = pkgs.fetchFromGitHub {
          owner = "level1techs";
          repo = "siomon";
          rev = "v0.1.2";
          hash = "sha256-I6JR3hwQ6sqEaBqC0uE8X6u4X7BCkgYsCe0QvDpcgXo=";
        };

        cargoHash = "sha256-O3XzIvbQytq+MAQ1TENMtCCkbR0AX+RbrSxXCS6b7Rw=";

        nativeBuildInputs = [
          pkgs.protobuf
          pkgs.pkg-config
        ];

        PROTOC = "${pkgs.protobuf}/bin/protoc";

        meta.mainProgram = "sio";
      };
    };
}
