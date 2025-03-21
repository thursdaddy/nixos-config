{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.ntfy;
in
{
  options.mine.cli-tools.ntfy = {
    enable = mkEnableOption "Ntfy cli";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ntfy-sh
    ];
  };
}
