{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.user;
  home-directory = "/Users/${cfg.name}";

in
{
  options.mine.user = {
    enable = mkEnableOption "Enable User";
    name = mkOpt types.str "thurs" "User account name";
    alias = mkOpt types.str "thursdaddy" "My full alias";
    email = mkOpt types.str "thursdaddy@pm.me" "My Email";
    homeDir = mkOpt types.str "${home-directory}" "Home Directory Path";
    home-manager = mkOpt types.bool false "Enable home-manager";
  };

  config = mkIf cfg.enable {
    users.users.${cfg.name} = {
      name = "${cfg.name}";
      home = "${cfg.homeDir}";
      isHidden = false;
      shell = pkgs.zsh;
    };
  };
}
