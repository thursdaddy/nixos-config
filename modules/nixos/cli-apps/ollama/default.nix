{ lib, config, inputs, pkgs, ... }:
with lib;
let

  cfg = config.mine.cli-apps.ollama;

in {
  options.mine.cli-apps.ollama = {
    enable = mkEnableOption "Enable Ollama";
  };

  disabledModules = [ "services/misc/ollama.nix" ];
  imports = [ (inputs.unstable + "/nixos/modules/services/misc/ollama.nix") ];

  config = mkIf cfg.enable {

    nixpkgs.overlays = [
      (final: prev: {
        inherit (inputs.unstable.legacyPackages.${pkgs.system}) ollama;
      })
    ];

    services.ollama = {
      enable = true;
      acceleration = "rocm";
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8080 11434 ];
  };
}
