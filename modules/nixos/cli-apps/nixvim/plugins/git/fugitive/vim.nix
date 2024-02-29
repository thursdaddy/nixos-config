{ ... }: {

  programs.nixvim = {
     plugins = {
       fugitive = { enable = true; };
     };

     keymaps = [
     # Git
     { mode = "n"; key = "<leader>gs"; action = "<CMD>below Git<CR>"; options.noremap = true; }
     { mode = "n"; key = "<leader>gc"; action = "<CMD>below Git commit<CR>"; options.noremap = true; }
     { mode = "n"; key = "<leader>gb"; action = "<CMD>GBranches<CR>"; options.noremap = true; }
     { mode = "n"; key = "<leader>gp"; action = "<CMD>Git push<CR>"; options.noremap = true; }
     { mode = "n"; key = "<leader>gl"; action = "<CMD>Git pull<CR>"; options.noremap = true; }
     { mode = "n"; key = "<leader>gcb"; action = "<CMD>Git blame<CR>"; options.noremap = true; }

     # Conflict choices
     { mode = "n"; key = "<leader>g,"; action = "<CMD>diffget //2<CR>"; options.noremap = true; }
     { mode = "n"; key = "<leader>g."; action = "<CMD>diffget //3<CR>"; options.noremap = true; }
     ];

  };

}
