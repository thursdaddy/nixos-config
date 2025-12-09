{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.fonts;

in
{
  options.mine.system.fonts = {
    enable = mkEnableOption "Enable Fonts";
  };

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        jetbrains-mono
        monaspace
        fira-sans
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.hack
        nerd-fonts.geist-mono
        nerd-fonts.fira-mono
      ];
    };
  };
}
