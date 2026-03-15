{ config, inputs, ... }:
let
  nixosModules = config.flake.modules.nixos;
  hmModules = inputs.self.modules.homeManager;

  sharedModules = [
    "dev"
  ];
in
{
  configurations.nixos.rpi4.module = {
    imports =
      with nixosModules;
      [
        base
        services
        home
      ]
      ++ (map (name: nixosModules.${name}) sharedModules)
      ++ [
        (
          { config, ... }:
          {
            home-manager.users.${config.mine.base.user.name}.imports = map (
              name: hmModules.${name}
            ) sharedModules;
          }
        )
      ];
  };
}
