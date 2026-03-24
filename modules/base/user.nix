{
  inputs,
  ...
}:
{
  config.flake.modules.generic.base =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (config.mine.base) user;
    in
    {
      options.mine.base.user = {
        alias = lib.mkOption {
          type = lib.types.str;
          default = "thursdaddy";
          description = "Full Alias";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "thursdaddy@pm.me";
          description = "Email";
        };
        home-manager.enable = lib.mkEnableOption "Enable home-manager";
        homeDir = lib.mkOption {
          type = lib.types.str;
          default =
            if pkgs.stdenv.isDarwin then
              "/Users/${config.mine.base.user.name}"
            else
              "/home/${config.mine.base.user.name}";
          description = "Home Directory Path";
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "thurs";
          description = "User account name";
        };
        shell.package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.fish;
        };
      };

      config = {
        users.users.${user.name} = {
          openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys.outPath ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs"
          ];
          shell = user.shell.package;
        };

        environment.variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
        };
      };
    };

  config.flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;
    in
    {
      users.groups.${user.name} = { };
      users.users.${user.name} = {
        isNormalUser = true;
        createHome = true;
        uid = 1000;
        group = user.name;
        extraGroups = [ "wheel" ];
      };

      programs = {
        fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;
        zsh.enable = lib.mkIf (user.shell.package == pkgs.zsh) true;
      };

      nix.settings.trusted-users = [ user.name ];

    };

  config.flake.modules.darwin.base =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;
    in
    {
      users.users.${user.name} = {
        name = "${user.name}";
        home = "${user.homeDir}";
        isHidden = false;
        uid = 501;
      };

      users.knownUsers = [ "${user.name}" ];

      programs = {
        fish.enable = lib.mkIf (user.shell.package == pkgs.fish) true;
        zsh.enable = lib.mkIf (user.shell.package == pkgs.zsh) true;
      };
    };

}
