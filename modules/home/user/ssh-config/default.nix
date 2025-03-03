{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.home-manager.ssh-config;

  domainName = config.nixos-thurs.localDomain;
in
{
  options.mine.home-manager.ssh-config = {
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
            sendEnv = [ "TERM" ];
            setEnv = { TERM = "xterm-256color"; };
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
          "git.${domainName}" = {
            hostname = "git.${domainName}";
            identitiesOnly = true;
            identityFile = "~/.ssh/git";
            port = 2222;
          };
        };
      };
    };
  };
}
