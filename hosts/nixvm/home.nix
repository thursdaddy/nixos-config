{ home-manager, username, pkgs, ... }: {

    programs.home-manager.enable = true;

    imports = [
      ./../../modules/home/git
      ./../../modules/home/zsh
      ./../../lib
      ./options.nix
    ];

    home.username = "${username}";
    home.homeDirectory = "/home/${username}";
    home.stateVersion = "23.11";
    home.packages = [
        pkgs.neovim
    ];

}
