{ inputs, ... }:
let
  homeConf =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      home-manager = {
        useGlobalPkgs = true;
        users.${config.mine.base.user.name}.imports = [
          (
            { osConfig, ... }:
            {
              programs.home-manager.enable = true;
              home = {
                username = osConfig.mine.base.user.name;
                stateVersion = lib.mkDefault osConfig.system.stateVersion;
                homeDirectory = osConfig.mine.base.user.homeDir;
              };
            }
          )
        ];
      };
    };
in
{
  flake.modules.nixos.home =
    { config, ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        homeConf
      ];
    };
  flake.modules.darwin.home =
    { config, ... }:
    {
      imports = [
        inputs.home-manager.darwinModules.home-manager
        homeConf
      ];
      home-manager.users.${config.mine.base.user.name}.home.stateVersion = "24.11";
    };
}
