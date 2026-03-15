{ config, inputs, ... }:
let
  nixosModules = config.flake.modules.nixos;
  hmModules = inputs.self.modules.homeManager;

  sharedModules = [
    "dev"
    "desktop"
    "apps"
  ];
in
{
  configurations.nixos.c137.module = {
    imports =
      with nixosModules;
      [
        base
        home
        services
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
