{
  config,
  inputs,
  ...
}:
{
  configurations.nixos.tailpi.module = {
    imports =
      with config.flake.modules.nixos;
      [
        base
        services
      ]
      ++ [
        inputs.nixos-thurs.nixosModules.tailnet-bastion
      ];
  };
}
