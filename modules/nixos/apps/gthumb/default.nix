{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.gthumb;

in
{
  options.mine.apps.gthumb = {
    enable = mkEnableOption "Gthumb";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gthumb
    ];
  };
}
