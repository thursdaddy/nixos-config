{ home-manager, username, ... }: {

    programs.home-manager.enable = true;

    imports = [
      ./../../modules/home/git
      ./../../modules/home/zsh
    ];

    home.username = "${username}";
    home.homeDirectory = "/home/${username}";
    home.stateVersion = "23.11";

}
