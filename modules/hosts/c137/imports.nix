{
  config,
  inputs,
  ...
}:
{
  configurations.nixos.c137.module = {
    imports =
      with config.flake.modules.nixos;
      [
        apps
        base
        containers
        dev
        desktop
        services
      ]
      ++ [
        inputs.nixos-thurs.nixosModules.tailnet-client
      ];
  };
}
