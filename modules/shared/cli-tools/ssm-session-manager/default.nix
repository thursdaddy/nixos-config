{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.ssm-session-manager;

in
{
  options.mine.cli-tools.ssm-session-manager = {
    enable = mkEnableOption "Enable AWS ssm-session-manager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ssm-session-manager-plugin
    ];
  };
}
