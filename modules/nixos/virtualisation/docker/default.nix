{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.virtualisation.docker;
  user = config.mine.user;

in
{
  options.mine.system.virtualisation.docker = {
    enable = mkEnableOption "docker";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    users.users.${user.name}.extraGroups = mkIf user.enable [ "docker" ];
  };
}
