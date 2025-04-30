{
  lib,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.nix.substituters;

in
{
  options.mine.system.nix.substituters = {
    enable = mkEnableOption "Enable Flakes";
  };

  config = mkIf cfg.enable {
    nix.settings.substituters = [ "http://192.168.10.15:8080" ];
  };
}
