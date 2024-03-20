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
      shell.zsh = enabled;
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
    };

    cli-apps = {
      homebrew = enabled;
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
