{ lib, config, inputs, ... }:
with lib;
let

  cfg = config.mine.apps.ghostty;

in
{
  options.mine.apps.ghostty = {
    enable = mkEnableOption "Ghostty";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.ghostty.packages.x86_64-linux.default
    ];
  };
}
