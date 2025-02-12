{ lib, config, pkgs, inputs, ... }:
let

  inherit (lib) mkEnableOption mkOption mkIf types;
  inherit (lib.thurs) mkOpt;
  inherit (config.mine) user;

  home-directory = "/home/${user.name}";

in
{
  options.mine.user = {
    enable = mkEnableOption "Enable User";
    name = mkOpt types.str "thurs" "User account name";
    alias = mkOpt types.str "thursdaddy" "Full alias";
    email = mkOpt types.str "thursdaddy@pm.me" "My Email";
    homeDir = mkOpt types.str "${home-directory}" "Home Directory Path";
    home-manager.enable = mkOpt types.bool false "Enable home-manager";
    ghToken.enable = mkEnableOption "Include GitHub access-tokens in nix.conf";
    shell = mkOption {
      default = { };
      description = "Shell config for user";
      type = types.submodule {
        options = {
          package = mkOpt types.package pkgs.fish "User shell";
          starship.enable = mkOpt types.bool true "Enable starship";
        };
      };
    };
  };

  config = mkIf user.enable {
    mine.system.shell.fish.enable = mkIf (user.shell.package == pkgs.fish) true;
    mine.system.shell.zsh.enable = mkIf (user.shell.package == pkgs.zsh) true;

    nix.settings.trusted-users = [ "${user.name}" ];

    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    systemd.user.extraConfig = ''
      DefaultEnvironment="PATH=/run/current-system/sw/bin"
    '';

    users.groups.${user.name} = { };

    users.users.${user.name} = {
      isNormalUser = true;
      createHome = true;
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys.outPath ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs" ];
      group = "${user.name}";
      extraGroups = [ "wheel" ];
      shell = user.shell.package;
    };

  };
}
