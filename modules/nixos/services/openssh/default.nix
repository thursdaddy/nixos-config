{ lib, config, ... }:
with lib;
let

  cfg = config.mine.services.openssh;

in
{
  options.mine.services.openssh = {
    enable = mkEnableOption "Enable OpenSSH";
    iso = mkEnableOption "If build is an iso";
  };

  config = mkIf cfg.enable {
    # Passwordless sudo when SSH'ing with keys
    security.pam.enableSSHAgentAuth = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin =
          if (cfg.iso)
          then "prohibit-password"
          else "no";
      };
    };
  };
}
