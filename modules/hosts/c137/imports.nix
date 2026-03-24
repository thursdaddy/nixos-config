{ config, inputs, ... }:
{
  configurations.nixos.c137.module = {
    imports = with config.flake.modules.nixos; [
      apps
      base
      dev
      desktop
      home
      services
    ];
  };
}
