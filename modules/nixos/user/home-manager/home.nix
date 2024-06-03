{ user, ... }: {

  programs.home-manager.enable = true;

  home.username = "${user.name}";
  home.homeDirectory = "${user.homeDir}";
  home.stateVersion = "24.05";

}
