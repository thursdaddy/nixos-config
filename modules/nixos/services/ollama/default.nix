{ lib, config, inputs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.ollama;

  host_c137 = config.mine.system.networking.networkmanager.hostname == "c137";

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
      environmentVariables = mkIf host_c137 {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };
    };
  };
}
