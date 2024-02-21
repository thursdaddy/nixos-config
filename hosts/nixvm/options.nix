{ lib, config, ... }: {

    myopt = {
        user = {
            enable = true;
            etc = "real test";
        };
        git = {
            enable = true;
        };
    };
}



#       myopt.user.enable = true;
#       myopt.user.etc = "real test";
#       myopt.git.enable = true;
