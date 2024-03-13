{ pkgs, lib, config, ... }:
with lib;
let
cfg = config.mine.nixos.ollama;

in {
  options.mine.nixos.ollama = {
    enable = mkEnableOption "Enable Ollama";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.ollama
      pkgs.rocmPackages.rpp
      pkgs.amdgpu_top
    ];

    # Open port for ollama-webui container
    networking.firewall = {
      allowedTCPPorts = [ 3000 ];
    };


  };

}
