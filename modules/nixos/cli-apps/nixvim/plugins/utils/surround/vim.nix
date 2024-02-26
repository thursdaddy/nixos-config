{ ... }: {

  programs.nixvim = {
     plugins = {
         surround = { enable = true; };
     };
  };

}
