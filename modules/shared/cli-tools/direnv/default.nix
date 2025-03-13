{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.direnv;

in
{
  options.mine.cli-tools.direnv = {
    enable = mkEnableOption "Enable direnv";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      direnv
    ];
  };
}
