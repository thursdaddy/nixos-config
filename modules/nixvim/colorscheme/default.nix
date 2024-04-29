{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.gruvbox-nvim ];
    colorscheme = "gruvbox";
  };
}
