{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.cli-tools.git;
  aliases = import ../../../shared/aliases.nix;

in
{
  options.mine.cli-tools.git = {
    enable = mkEnableOption "Git configs";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gh
    ];

    programs.fish.shellAliases = mkIf (
      user.shell.package == pkgs.fish || config.mine.system.shell.fish.enable
    ) aliases.git;
  };
}
