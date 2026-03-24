_: {
  flake.modules.nixos.desktop =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.desktop.amd;
    in
    {
      options.mine.desktop.amd = {
        enable = lib.mkEnableOption "Enable AMD Video Drivers";
      };

      config = lib.mkIf cfg.enable {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            libva
            libva-vdpau-driver
            libvdpau-va-gl
            mesa
            vulkan-extension-layer
            vulkan-loader
            vulkan-validation-layers
          ];
        };

        environment.systemPackages = with pkgs; [
          amdgpu_top
          mesa-demos
          rocmPackages.rocm-smi
        ];
      };
    };
}
