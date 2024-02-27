{ ... }: {

  programs.nixvim = {
     plugins = {
       nvim-tree = { enable = true; };
     };

     keymaps = [
     { mode = "n"; key = "<leader>e"; action = "<CMD>NvimTreeToggle<CR>"; }
     { mode = "n"; key = "<leader>E"; action = "<CMD>NvimTreeFocus<CR>"; }
     ];
  };

}
