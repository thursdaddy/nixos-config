{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.mine.timezone;

  in {
    options.mine.timezone = {
      enable = mkEnableOption "Set Timezone";
    };

    config = mkIf cfg.enable {
      time.timeZone = "America/Phoenix";
     };

}
