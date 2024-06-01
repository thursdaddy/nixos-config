{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.services.ollama;

in
{
  options.mine.services.ollama = {
    enable = mkEnableOption "Enable Ollama";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 11434 ];

    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
      listenAddress = "0.0.0.0:11434";
      acceleration = "rocm";
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };
    };
  };
}
