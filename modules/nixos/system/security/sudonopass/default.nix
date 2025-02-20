{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.system.security.sudonopass;

in
{
  options.mine.system.security.sudonopass = {
    enable = mkEnableOption "Enable no password on sudo";
  };

  config = mkIf cfg.enable {
    security.sudo.extraRules = [{
      users = [ "${user.name}" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];
  };
}
