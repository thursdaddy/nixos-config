{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.openssh;

in {
  options.mine.nixos.openssh = {
    enable = mkEnableOption "Enable OpenSSH";
    iso = mkOpt types.bool false "If build is an iso";
  };

  config = mkIf cfg.enable {

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin =
          if (cfg.iso)
            then "yes"
          else "no";
      };
    };

    # Passwordless sudo when SSH'ing with keys
    security.pam.enableSSHAgentAuth = true;
  };

}
