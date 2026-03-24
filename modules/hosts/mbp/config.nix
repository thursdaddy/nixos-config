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

      mine = {
        base = {
          nix.ghToken = enabled;
        };

        desktop.aerospace = enabled;

        dev.tmux = {
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/projects/nix"
              "${user.homeDir}/projects/cloud"
              "${user.homeDir}/projects/homelab"
              "${user.homeDir}/projects/personal"
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
