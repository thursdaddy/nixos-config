{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.attic;
in
{
  options.mine.cli-tools.attic = {
    enable = mkEnableOption "Attic client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.attic-client
    ];
  };
}
