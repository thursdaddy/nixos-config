{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.user;
  home-directory = "/home/${cfg.name}";

in
{
  options.mine.user = {
    enable = mkEnableOption "Enable User";
    name = mkOpt types.str "thurs" "User account name";
    alias = mkOpt types.str "thursdaddy" "Full alias";
    email = mkOpt types.str "thursdaddy@pm.me" "My Email";
    homeDir = mkOpt types.str "${home-directory}" "Home Directory Path";
    home-manager = mkOpt types.bool false "Enable home-manager";
  };

  config = mkIf cfg.enable {
    nix.settings.trusted-users = [ "${cfg.name}" ];

    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    systemd.user.extraConfig = ''
      DefaultEnvironment="PATH=/run/current-system/sw/bin"
    '';

    users.users.${cfg.name} = {
      isNormalUser = true;
      createHome = true;
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys.outPath ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs" ];
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
    };

  };
}
