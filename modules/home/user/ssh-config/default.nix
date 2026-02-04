{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.home-manager.ssh-config;
in
{
  options.mine.home-manager.ssh-config = {
    enable = mkEnableOption "SSH config";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            addKeysToAgent = "yes";
            forwardAgent = true;
            identityFile = "~/.ssh/id_ed25519";
            sendEnv = [ "TERM" ];
            setEnv = {
              TERM = "xterm-256color";
            };
          };
          "192.168.20.222" = {
            identityFile = "~/.ssh/id_ed25519";
            extraOptions = {
              "StrictHostKeyChecking" = "no";
            };
          };
          "github.com" = {
            hostname = "github.com";
            identitiesOnly = true;
            identityFile = "~/.ssh/git";
          };
          "gitlab.com" = {
            hostname = "gitlab.com";
            identitiesOnly = true;
            identityFile = "~/.ssh/git";
          };
          "git.thurs.pw" = {
            hostname = "git.thurs.pw";
            identitiesOnly = true;
            identityFile = "~/.ssh/git";
            port = 2222;
          };
        };
      };
    };
  };
}
