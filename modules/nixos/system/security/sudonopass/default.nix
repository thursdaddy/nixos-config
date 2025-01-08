{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.security.sudonopass;
  inherit (config.mine) user;

in
{
  options.mine.system.security.sudonopass = {
    enable = mkEnableOption "zsh";
  };

  # TODO: account for when user not enabled, if possible
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
