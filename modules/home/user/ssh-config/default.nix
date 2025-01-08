{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.user.ssh-config;
  inherit (config.mine) user;

in
{
  options.mine.user.ssh-config = {
    enable = mkEnableOption "SSH config";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.ssh = {
        enable = true;
        forwardAgent = true;
        addKeysToAgent = "yes";
        matchBlocks = {
          "*" = {
            identityFile = "~/.ssh/id_ed25519";
          };
          "192.168.20.222" = {
            identityFile = "~/.ssh/id_ed25519";
            extraOptions = {
              "StrictHostKeyChecking" = "no";
            };
          };
          "cloudbox" = {
            hostname = "100.114.203.99";
            identitiesOnly = true;
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
