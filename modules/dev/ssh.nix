_: {
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      options,
      ...
    }:
    let
      inherit (config.mine.base) user;
    in
    {
      config =
        {
          programs.ssh = {
            extraConfig = ''
              Match all
                AddKeysToAgent yes
                ForwardAgent yes
                AddressFamily inet
                IdentityFile ${user.homeDir}/.ssh/id_ed25519
                ControlMaster auto
                ControlPath ~/.ssh/ssh-%r@%h:%p
                ControlPersist 60m
                ServerAliveInterval 30
                ServerAliveCountMax 3
                ConnectTimeout 5

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

              Host gitea.thurs.pw
                Port 222
                IdentitiesOnly yes
                IdentityFile ${user.homeDir}/.ssh/git

              Host wormhole 192.168.10.51
                HostName 192.168.10.51
                RemoteForward /run/user/1000/gnupg/S.gpg-agent ${user.homeDir}/.gnupg/S.gpg-agent.extra
                StreamLocalBindUnlink yes
            '';
          }
          // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
            agentTimeout = "24h";
          };
        }
        // lib.optionalAttrs (options ? systemd) {
          systemd.user.tmpfiles.rules = [
            "d %t/gnupg 0700 - - - -"
          ];
        };
    };
}
