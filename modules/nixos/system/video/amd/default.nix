{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.video.amd;

in
{
  options.mine.system.video.amd = {
    enable = mkEnableOption "Enable AMD Video Drivers";
  };

  config = mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
      ];
    };
    environment.systemPackages = with pkgs; [
      mesa-demos
      amdgpu_top
      rocmPackages.rocm-smi
    ];
  };
}
