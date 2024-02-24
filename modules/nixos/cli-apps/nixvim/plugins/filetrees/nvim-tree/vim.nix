{ ... }: {

  programs.nixvim = {
     plugins = {
         nvim-tree = { enable = true; };
     };
  };

}
