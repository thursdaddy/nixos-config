{ config, ... }:
{
  configurations.nixos.homebox.module = {
    imports = with config.flake.modules.nixos; [
      celler
      base
      containers
      home-assistant
      services
    ];
  };
}
