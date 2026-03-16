{ config, inputs, ... }:
let
  nixosModules = config.flake.modules.nixos;
  hmModules = inputs.self.modules.homeManager;

  sharedModules = [
    "dev"
  ];
in
{
  configurations.nixos.homebox.module = {
    imports =
      with nixosModules;
      [
        attic
        base
        blocky
        containers
        home
        home-assistant
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
