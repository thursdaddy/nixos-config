{
  lib,
  config,
  inputs,
  ...
}:
let

  inherit (lib) mkIf;
  inherit (config.mine) user;
  cfg = config.mine.user.home-manager;

  allowed-unfree-packages = [ "discord" ];

in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      extraSpecialArgs = {
        inherit inputs;
        inherit user;
        inherit allowed-unfree-packages;
      };
      users.${user.name}.imports = [ ./home.nix ];
    };
  };
}
