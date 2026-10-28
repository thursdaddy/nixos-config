_: {
  flake.modules.nixos.desktop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let

      inherit (lib) mkEnableOption mkIf;
      cfg = config.mine.desktop.antigravity;

    in
    {
      options.mine.desktop.antigravity = {
        enable = mkEnableOption "antigravity";
      };

      config = mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.antigravity
        ];
      };
    };
}
