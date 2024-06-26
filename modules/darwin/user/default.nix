{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;
  home-directory = "/Users/${user.name}";

in
{
  options.mine.user = {
    enable = mkEnableOption "Enable User";
    name = mkOpt types.str "thurs" "User account name";
    alias = mkOpt types.str "thursdaddy" "My full alias";
    email = mkOpt types.str "thursdaddy@pm.me" "My Email";
    homeDir = mkOpt types.str "${home-directory}" "Home Directory Path";
    home-manager.enable = mkOpt types.bool false "Enable home-manager";
    ghToken.enable = mkEnableOption "deploy ghToken used with build script";
  };

  config = mkIf user.enable {
    users.users.${user.name} = {
      name = "${user.name}";
      home = "${user.homeDir}";
      isHidden = false;
      shell = pkgs.zsh;
    };
  };
}
