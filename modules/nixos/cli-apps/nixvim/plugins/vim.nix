{ ... }: {

  programs.nixvim = {
     plugins = {
         lualine = { enable = true; };
         nvim-tree = { enable = true; };
         luasnip = { enable = true; };
         cmp-buffer  = { enable = true; };
         cmp-emoji  = { enable = true; };
         cmp-nvim-lsp  = { enable = true; };
         cmp-path = { enable = true; };
     };
  };

}
