{ home-manager, username, pkgs, ... }: {

    programs.home-manager.enable = true;

    home.username = "${username}";
    home.homeDirectory = "/home/${username}";
    home.stateVersion = "23.11";
    home.packages = [
        pkgs.neovim
    ];

}
