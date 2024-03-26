{ pkgs, lib, config, inputs, ... }:
with lib;
let

  cfg = config.mine.cli-apps.ollama;
  unstablePkgs = import inputs.unstable { system = "x86_64-linux"; };
in {
  options.mine.cli-apps.ollama = {
    enable = mkEnableOption "Enable Ollama";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      unstablePkgs.ollama
      pkgs.amdgpu_top
    ];

    services.ollama.acceleration = "rocm";
    networking.firewall.allowedTCPPorts = [ 3000 ];
  };
}
