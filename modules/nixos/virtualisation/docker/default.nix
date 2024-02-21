{ lib, username, config, ... }:
let
    cfg = config.myopt.docker;
in {
    options.myopt.docker = {
        enable = lib.mkEnableOption "docker";
    };

    config = lib.mkIf cfg.enable  {

        virtualisation.docker.enable = true;

        users.users.${username}.extraGroups = [ "docker" ];

    };

}
