{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.crush;
in
{
  options.mine.cli-tools.crush = {
    enable = mkEnableOption "Crush, terminal based AI coding agent";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.unstable.crush
    ];
  };
}
