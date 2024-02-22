{ lib, username, config, ... }:
let
    cfg = config.mine.docker;

in {
    options.mine.docker = {
        enable = lib.mkEnableOption "docker";
    };

    config = lib.mkIf cfg.enable  {

        virtualisation.docker.enable = true;
        users.users.${username}.extraGroups = [ "docker" ];

    };

}
