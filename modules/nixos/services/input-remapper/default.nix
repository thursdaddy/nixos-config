{ lib, config, ... }:
with lib;
let

  cfg = config.mine.services.input-remapper;

in
{
  options.mine.services.input-remapper = {
    enable = mkEnableOption "Enable input-remapper";
  };

  config = mkIf cfg.enable {
    # re-map kensington trackball buttons
    services.input-remapper = {
      enable = true;
    };
  };
}
