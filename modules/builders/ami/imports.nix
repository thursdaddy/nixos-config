{ config, ... }:
{
  configurations.nixos.ami.module = {
    imports = with config.flake.modules.nixos; [
      base
      services
    ];
  };
}
