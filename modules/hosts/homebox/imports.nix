{ config, ... }:
{
  configurations.nixos.homebox.module = {
    imports = with config.flake.modules.nixos; [
      attic
      base
      blocky
      dev
      home-assistant
      services
    ];
  };
}
