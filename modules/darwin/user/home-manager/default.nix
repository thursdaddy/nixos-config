{ lib, config, inputs, ... }:
with lib;
let

  cfg = config.mine.user.home-manager;
  inherit (config.mine) user;

  allowed-unfree-packages = [ "discord" ];

in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      extraSpecialArgs = { inherit inputs; inherit user; inherit allowed-unfree-packages; };
      users.${user.name}.imports = [ ./home.nix ];
    };
  };
}
