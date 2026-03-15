_: {
  flake.modules.generic.desktop =
    { pkgs, ... }:
    {
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
