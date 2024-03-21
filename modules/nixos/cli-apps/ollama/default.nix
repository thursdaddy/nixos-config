{ pkgs, lib, config, ... }:
with lib;
let

  cfg = config.mine.cli-apps.ollama;

in {
  options.mine.cli-apps.ollama = {
    enable = mkEnableOption "Enable Ollama";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.ollama
      pkgs.rocmPackages.rpp
      pkgs.amdgpu_top
    ];

    networking.firewall.allowedTCPPorts = [ 3000 ];
  };
}
