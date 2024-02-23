{ lib, config, ... }:
with lib;
with lib.thurs;
let
  cfg = config.mine.nixos.docker;
  user = config.mine.nixos.user;

in {
    options.mine.nixos.docker = {
        enable = mkEnableOption "docker";
    };

    config = lib.mkIf cfg.enable  {

        virtualisation.docker.enable = true;
        users.users.${user.name}.extraGroups = [ "docker" ];

    };

}
