{ lib, config, pkgs, inputs, ... }:
with lib;
let

  cfg = config.mine.services.ollama;

in
{
  options.mine.services.ollama = {
    enable = mkEnableOption "Enable Ollama";
  };

  disabledModules = [ "services/misc/ollama.nix" ];
  imports = [ (inputs.unstable + "/nixos/modules/services/misc/ollama.nix") ];

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 11434 ];

    services.ollama = {
      enable = true;
      # package = pkgs.unstable.ollama;
      host = "0.0.0.0";
      port = 11434;
      acceleration = "rocm";
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };
    };
  };
}
