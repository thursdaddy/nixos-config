{ lib, config, pkgs, inputs, ... }:
let

  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.thurs) mkOpt;
  inherit (config.mine) user;

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
    ghToken.enable = mkEnableOption "Include GitHub access-tokens in nix.conf";
  };

  config = mkIf user.enable {
    users.users.${user.name} = {
      name = "${user.name}";
      home = "${user.homeDir}";
      isHidden = false;
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys.outPath ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs" ];
    };
  };
}
