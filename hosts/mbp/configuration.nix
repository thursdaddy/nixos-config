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

  system.checks.verifyNixPath = false;
  services.nix-daemon.enable = true;
  programs.nix-index.enable = false;

  mine = {
    user = enabled;

    system = {
      nix.flakes = enabled;
      shells.zsh = enabled;
      security.touchsudo = enabled;
    };

    tools = {
      git = enabled;
      home-manager = enabled;
    };

    apps = {
      kitty = enabled;
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
