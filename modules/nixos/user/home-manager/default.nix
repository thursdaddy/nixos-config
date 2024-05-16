{ lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.user;
  user = config.mine.user;

  # TODO: refactor this so its not randomly in user config
  allowed-unfree-packages = [
    "discord"
  ];

in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = mkIf cfg.home-manager {
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit inputs; inherit user; inherit allowed-unfree-packages; };
    home-manager.users.${user.name}.imports = [ ./home.nix ];
  };
}
