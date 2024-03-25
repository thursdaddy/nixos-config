{ lib, config, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in {

  imports = [
    ../../modules/darwin/import.nix
    ../../modules/home/import.nix
  ];

  mine = {
    user = enabled;

    system = {
      security.touchsudo = enabled;
      utils = enabled;
    };

    tools = {
      direnv = enabled;
      git = enabled;
      home-manager = enabled;
    };

    apps = {
      kitty = enabled;
      discord = enabled;
      syncthing = enabled;
      firefox = enabled;
      chromium = enabled;
      obsidian = enabled;
    };

    cli-apps = {
      homebrew = enabled;
      neofetch = enabled;
      nixvim = enabled;
      tmux = {
        enable = true;
        sessionizer = {
          enable = true;
          searchPaths = [
            "${user.homeDir}/projects/nixos"
            "${user.homeDir}/projects/cloud"
          ];
        };
      };
    };
  };
}
