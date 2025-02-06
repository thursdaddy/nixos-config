{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.ssm-agent;

in
{
  options.mine.services.ssm-agent = {
    enable = mkEnableOption "Enable AWS ssm-agent";
  };

  config = mkIf cfg.enable {
    services.amazon-ssm-agent.enable = true;
  };
}
