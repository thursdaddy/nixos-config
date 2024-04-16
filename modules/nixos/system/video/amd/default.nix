{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.video.amd;

in
{
  options.mine.system.video.amd = {
    enable = mkEnableOption "Enable AMD Video Drivers";
  };

  config = mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
      ];
    };
    environment.systemPackages = with pkgs; [
      glxinfo
      amdgpu_top
    ];
  };
}
