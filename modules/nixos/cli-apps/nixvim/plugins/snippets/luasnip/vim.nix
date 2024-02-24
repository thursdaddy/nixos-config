{ ... }: {

  programs.nixvim = {
     plugins = {
         luasnip = { enable = true; };
     };
  };

}
