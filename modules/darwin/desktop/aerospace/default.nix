{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.desktop.aerospace;

in
{
  options.mine.desktop.aerospace = {
    enable = mkEnableOption "aerospace";
  };

  config = mkIf cfg.enable {
    services = {
      aerospace = {
        enable = true;
      };
    };
  };
}
