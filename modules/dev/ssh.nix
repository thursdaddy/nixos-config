_: {
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;
    in
    {
      programs.ssh = {
        extraConfig = ''
          Match all
            AddKeysToAgent yes
            ForwardAgent yes
            IdentityFile ${user.homeDir}/.ssh/id_ed25519

          Host github.com
            HostName github.com
            IdentitiesOnly yes
            IdentityFile ${user.homeDir}/.ssh/git

          Host gitlab.com
            HostName gitlab.com
            IdentitiesOnly yes
            IdentityFile ${user.homeDir}/.ssh/git

          Host git.thurs.pw
            HostName git.thurs.pw
            Port 2222
            IdentitiesOnly yes
            IdentityFile ${user.homeDir}/.ssh/git
        '';
      }
      // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        agentTimeout = "24h";
      };
    };
}
