{
  config,
  inputs,
  ...
}:
{
  configurations.darwin.mbp.module = {
    imports =
      with config.flake.modules.darwin;
      [
        apps
        base
        desktop
        dev
      ]
      ++ [
        inputs.nixos-thurs.darwinModules.tailnet-client
      ];
  };
}
