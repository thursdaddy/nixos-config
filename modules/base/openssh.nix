_: {
  flake.modules.nixos.base =
    {
      lib,
      config,
      inputs,
      ...
    }:
    let
      cfg = config.mine.base.openssh;
    in
    {
      options.mine.base.openssh = {
        root = lib.mkEnableOption "Allow root login via SSH Keys";
      };

      config = {
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = if cfg.root then "prohibit-password" else lib.mkDefault "no";
          };
        };

        users.users.root.openssh.authorizedKeys.keyFiles = lib.mkIf cfg.root [ inputs.ssh-keys.outPath ];

        # Passwordless sudo when SSH'ing with keys
        security.pam.sshAgentAuth.enable = true;
        programs.ssh.startAgent = true;
      };
    };
}
