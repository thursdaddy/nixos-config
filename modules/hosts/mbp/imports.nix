{ config, inputs, ... }:
let
  darwinModules = config.flake.modules.darwin;
  hmModules = inputs.self.modules.homeManager;

  sharedModules = [
    "dev"
    "apps"
    "base"
    "desktop"
  ];
in
{
  configurations.darwin.mbp.module = {
    imports =
      with darwinModules;
      [
        home
      ]
      ++ (map (name: darwinModules.${name}) sharedModules)
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
