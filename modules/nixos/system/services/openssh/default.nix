{
  lib,
  config,
  inputs,
  ...
}:
let

  inherit (lib) mkEnableOption mkDefault mkIf;
  cfg = config.mine.system.services.openssh;

in
{
  options.mine.system.services.openssh = {
    enable = mkEnableOption "Enable OpenSSH";
    root = mkEnableOption "Allow root login via SSH Keys";
  };

  config = mkIf cfg.enable {
    users.users.root.openssh.authorizedKeys.keyFiles = mkIf cfg.root [ inputs.ssh-keys.outPath ];

    # Passwordless sudo when SSH'ing with keys
    security.pam.sshAgentAuth.enable = true;
    programs.ssh.startAgent = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = if cfg.root then "prohibit-password" else mkDefault "no";
      };
    };
  };
}
