_: {
  flake.modules.nixos.desktop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.mine.desktop.sddm;
    in
    {
      options.mine.desktop.sddm = {
        enable = lib.mkEnableOption "Enable SDDM";
      };

      config = lib.mkIf cfg.enable {
        services.displayManager.sddm = {
          enable = true;
          theme = "Elegant";
        };

        environment.systemPackages = [
          pkgs.elegant-sddm
        ];
      };
    };
}
