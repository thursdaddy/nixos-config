_: {
  flake.modules.homeManager.dev =
    { config, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            addKeysToAgent = "yes";
            forwardAgent = true;
            identityFile = "~/.ssh/id_ed25519";
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
}
