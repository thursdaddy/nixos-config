_: {
  flake.modules.generic.base =
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
      config = lib.mkIf (user.shell.package == pkgs.zsh) {
        programs.zsh.enable = true;
        environment.pathsToLink = [ "/share/zsh" ];
      };
    };
}
