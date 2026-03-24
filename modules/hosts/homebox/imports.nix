{ config, ... }:
{
  configurations.nixos.homebox.module = {
    imports = with config.flake.modules.nixos; [
      attic
      base
      blocky
      containers
      dev
      home
      home-assistant
      services
    ];
  };
}
