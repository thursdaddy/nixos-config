{ home-manager, username, pkgs, ... }: {

    imports = [
      ../../modules/home/import.nix
    ];

    programs.home-manager.enable = true;

    home.username = "${username}";
    home.homeDirectory = "/home/${username}";
    home.stateVersion = "23.11";
    home.packages = [
        pkgs.neovim
    ];

}
