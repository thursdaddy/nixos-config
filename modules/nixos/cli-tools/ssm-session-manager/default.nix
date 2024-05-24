{ lib, config, pkgs, ... }:
with lib;
let
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
