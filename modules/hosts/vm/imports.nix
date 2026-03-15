{ config, inputs, ... }:
{
  configurations.nixos.vm.module = {
    imports =
      with config.flake.modules.nixos;
      [
        base
        dev
        home
        containers
      ]
      ++ [
        (
          { config, ... }:
          {
            home-manager.users.${config.mine.base.user.name}.imports = with inputs.self.modules.homeManager; [
              dev
            ];
          }
        )
      ];
  };
}
