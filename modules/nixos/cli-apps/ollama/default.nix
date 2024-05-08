{ lib, config, inputs, pkgs, ... }:
with lib;
let

  cfg = config.mine.cli-apps.ollama;

in
{
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
      # ollama build fails due to rocm issues, overrding package version does not fix it.
      # possibly related to this:
      # https://github.com/NixOS/nixpkgs/issues/305641
      # disabling for now as im not really using ollama
      (self: super: {
        ollama = super.ollama.overrideAttrs
          (old: rec {
            version = "0.1.31";
            src = super.fetchFromGitHub {
              owner = "jmorganca";
              repo = "ollama";
              rev = "v${version}";
              hash = "sha256-Ip1zrhgGpeYo2zsN206/x+tcG/bmPJAq4zGatqsucaw=";
              fetchSubmodules = true;
            };
          });
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
