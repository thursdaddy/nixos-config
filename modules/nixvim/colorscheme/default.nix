{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.gruvbox-nvim ];
    extraConfigLua = ''
      require("gruvbox").setup({
          transparent_mode = true,
      })
      vim.cmd("colorscheme gruvbox")
    '';
  };
}
