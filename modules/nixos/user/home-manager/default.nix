{ lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.user.home-manager;
  inherit (config.mine) user;

  # TODO: refactor this so its not randomly in user config
  allowed-unfree-packages = [
    "discord"
  ];

in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; inherit user; inherit allowed-unfree-packages; };
      users.${user.name}.imports = [ ./home.nix ];
    };
  };
}
