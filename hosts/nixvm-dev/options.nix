{ lib, config, ... }: {
    options = {
        myopt.user = lib.mkOption {
            default = {};
            type = lib.types.submodule {
                options.etc = lib.mkOption {
                    type = lib.types.str;
                    default = "This is a default value";
                };
            };
        };
        myopt.git = lib.mkOption {
            default = {};
            type = lib.types.submodule { };
        };
    };

    config = {
        myopt = {
            user = {
                enable = true;
                etc = "real test";
            };
            git = {
                enable = true;
            };
        };

    };
}



#       myopt.user.etc = "test test";
#       myopt.git.enable = true;
#       myopt.user.enable = true;
