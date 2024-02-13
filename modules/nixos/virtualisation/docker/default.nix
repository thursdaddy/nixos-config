{ lib, username, config, ... }:
let
    cfg = config.myopt.user;
in {
    options.myopt.user = {
        enable = lib.mkEnableOption "user";
    };

    config = lib.mkIf config.myopt.user.enable  {

        virtualisation.docker.enable = true;

        users.users.${username}.extraGroups = [ "docker" ];

        environment.etc.userNAME.text = config.myopt.user.etc;
    };

}
