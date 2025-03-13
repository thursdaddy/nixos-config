{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.fastfetch;

in
{
  options.mine.cli-tools.fastfetch = {
    enable = mkEnableOption "Enable fastfetch";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fastfetch
    ];
  };
}
