{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.system.fonts;

in
{
  options.mine.system.fonts = {
    enable = mkOpt types.bool false "Enable Fonts";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      monaspace
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "Hack" "GeistMono" ]; })
    ];
  };
}
