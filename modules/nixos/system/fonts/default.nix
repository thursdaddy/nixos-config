{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.fonts;

in {
  options.mine.nixos.fonts = {
    enable = mkOpt types.bool false "Enable Fonts";
  };

  config = mkIf cfg.enable {

    environment.variables = {
      LOG_ICONS = "true";
    };

    environment.systemPackages = with pkgs; [font-manager];

    fonts.packages = with pkgs;
    [
      noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
        (nerdfonts.override {fonts = ["Hack"];})
    ];
  };

}
