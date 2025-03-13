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
      extraSpecialArgs = {
        inherit inputs;
        inherit user;
        inherit allowed-unfree-packages;
      };
      users.${user.name}.imports = [ ./home.nix ];
    };
  };
}
