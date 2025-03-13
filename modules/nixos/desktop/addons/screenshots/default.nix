{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.desktop.screenshots;

in
{
  options.mine.desktop.screenshots = {
    enable = mkEnableOption "Enable screenshots with grim and slurp";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      grim
      slurp
    ];
  };

}
