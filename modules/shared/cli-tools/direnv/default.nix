{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.cli-tools.direnv;
in
{
  options.mine.cli-tools.direnv = {
    enable = mkEnableOption "Enable direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
        package = pkgs.nix-direnv;
      };
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      enableFishIntegration = mkIf (user.shell.package == pkgs.fish) true;
      enableZshIntegration = mkIf (user.shell.package == pkgs.zsh) true;
    };
  };
}
