{ config, ... }:
{
  configurations.nixos.homebox.module = {
    imports = with config.flake.modules.nixos; [
      attic
      base
      containers
      home-assistant
      services
    ];
  };
}
