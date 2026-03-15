_: {
  flake.modules.generic.dev =
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
      environment.systemPackages = with pkgs; [
        gh
        git
      ];

      programs.fish.shellAliases = lib.mkIf (user.shell.package == pkgs.fish) config.mine.aliases.git;
    };

  flake.modules.homeManager.dev =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      inherit (osConfig.mine.base) user;
    in
    {
      programs.git = {
        enable = true;
        includes = [
          {
            path = "~/projects/nix/nixos-thurs/.gitconfig";
            condition = "gitdir:~/projects/nix/nixos-thurs/";
          }
        ];
        settings = {
          user = {
            name = "${user.name}";
            email = "${user.email}";
          };
          safe.directory = "*";
          init = {
            defaultBranch = "main";
          };
          pull = {
            rebase = false;
          };
          push = {
            autoSetupRemote = true;
          };
          core = {
            editor = "nvim";
          };
        };
      };

      programs.zsh.shellAliases = lib.mkIf (user.shell.package == pkgs.zsh) config.mine.aliases.git;
    };
}
