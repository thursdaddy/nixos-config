_: {
  configurations.nixos.vm.module =
    { config, lib, ... }:
    let
      inherit (config.mine.base) user;
      inherit (lib.thurs) enabled;
    in
    {
      mine = {
        base = {
          utils.sysadmin = enabled;
          nix.ghToken = enabled;
        };

        home-manager = {
          tmux = {
            sessionizer = {
              enable = true;
              searchPaths = [
                "${user.homeDir}/"
              ];
            };
          };
        };
      };
    };
}
