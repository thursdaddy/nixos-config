{ lib, config, inputs, pkgs, ... }:
with lib;
let

  cfg = config.mine.cli-apps.ollama;

in
{
  options.mine.cli-apps.ollama = {
    enable = mkEnableOption "Enable Ollama";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
      listenAddress = "0.0.0.0:11434";
      acceleration = "rocm";
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };
    };

    networking.firewall.allowedTCPPorts = [ 11434 ];
  };
}
