{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.cli-tools.sops;
  user = config.mine.user;

in
{
  options.mine.cli-tools.sops = {
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
    home-manager.users.${user.name} = {
      sops = {
        defaultSopsFile = cfg.defaultSopsFile;
        age.keyFile = cfg.ageKeyFile.path;

        # this is defined in here because I use home-manager to mange git config and
        # only want to use the sop home-manager implementation on my darwin system.
        secrets."github/TOKEN" = mkIf (config.mine.cli-tools.git.ghToken) { };
      };
    };
  };
}
