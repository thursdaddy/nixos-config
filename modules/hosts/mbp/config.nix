_: {
  configurations.darwin.mbp.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
      inherit (config.mine.base) user;
    in
    {
      nix.linux-builder = {
        enable = true;
        systems = [
          "aarch64-linux"
          "x86_64-linux"
        ];
        config = {
          boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
        };
      };

      nix.settings.trusted-users = [ "@admin" ];

      mine = {
        base = {
          nix.ghToken = enabled;
        };

        dev.tmux = {
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/dev/nix"
              "${user.homeDir}/dev/cloud"
              "${user.homeDir}/dev/homelab"
            ];
          };
        };
      };

      # https://nixpk.gs/pr-tracker.html?pr=400290
      nixpkgs.overlays = [
        (self: super: {
          nodejs = super.nodejs_22;
          nodejs-slim = super.nodejs-slim_22;
        })
      ];
    };
}
