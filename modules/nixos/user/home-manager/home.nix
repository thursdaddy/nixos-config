{ user, ... }: {

  programs.home-manager.enable = true;

  home = {
    username = "${user.name}";
    stateVersion = "24.11";
    homeDirectory = "${user.homeDir}";
  };
}
