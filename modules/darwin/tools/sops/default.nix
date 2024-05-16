{ lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.tools.sops;
  user = config.mine.user;

in
{
  options.mine.tools.sops = {
    enable = mkEnableOption "Enable sops";
    defaultSopsFile = mkOpt_ types.path "Default sops file used for all secrets.";
    ageKeyFile = mkOption {
      default = { };
      description = "ageKeyFile config";
      type = types.submodule {
        options = {
          path = mkOpt (types.nullOr types.path) null "Path to age key file used for sops decryption.";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    homebrew.brews = [ "sops" ];

    home-manager.users.${user.name} = {
      sops = {
        defaultSopsFile = cfg.defaultSopsFile;
        age.keyFile = cfg.ageKeyFile.path;
        secrets."github/TOKEN" = { };
      };
    };
  };
}
