{ lib, config, inputs, ... }:
with lib;
let

  cfg = config.mine.user.home-manager;
  user = config.mine.user;

  allowed-unfree-packages = [ "discord" ];

in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  config = mkIf cfg.enable {
    home-manager.useUserPackages = true;
    home-manager.useGlobalPkgs = true;
    home-manager.extraSpecialArgs = { inherit inputs; inherit user; inherit allowed-unfree-packages; };
    home-manager.users.${user.name}.imports = [ ./home.nix ];
  };
}
