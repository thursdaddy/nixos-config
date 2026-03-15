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
            mesa
            libva-vdpau-driver
            libvdpau-va-gl

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
    };
}
