{ lib, config, ... }:
with lib;
let
  cfg = config.mine.openssh;

  in {
    options.mine.openssh = {
      enable = mkEnableOption "Enable OpenSSH";
    };

    config = mkIf cfg.enable {
        services.openssh = {
          enable = true;
          settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
              # Automatically remove stale sockets
              StreamLocalBindUnlink = "yes";
          };
      };

      # Passwordless sudo when SSH'ing with keys
      security.pam.enableSSHAgentAuth = true;
    };

}
