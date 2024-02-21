{ lib, ... }:

with lib; {

   options = {
        myopt.docker = mkOption {
            default = {};
            type = types.submodule { };
        };

        myopt.git = mkOption {
            default = {};
            type = types.submodule { };
        };
   };

    #mkOpt = type: default: description:
    #    mkOption { inherit type default description; };

    #mkBoolOpt = mkOpt types.bool;

}
