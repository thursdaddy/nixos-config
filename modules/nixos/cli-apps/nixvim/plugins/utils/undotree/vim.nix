{ ... }: {

  programs.nixvim = {
     plugins = {
         undotree = { enable = true; };
     };
  };

}
