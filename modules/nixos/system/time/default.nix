{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.timezone;

in {
  options.mine.nixos.timezone = {
    enable = mkOpt types.bool false "Enable time";
    location = mkOpt types.str "America/Phoenix" "Timezone Location";
  };

  config = mkIf cfg.enable {
    time.timeZone = "${cfg.location}";
  };

}
