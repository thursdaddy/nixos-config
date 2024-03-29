{ ... }: {
  programs.nixvim = {
    globals.mapleader = " ";

    keymaps = [
    # Keep things centered
    { mode = "n"; key = "<C-h>"; action = "<CMD>wincmd h<CR>zz"; }
    { mode = "n"; key = "<C-j>"; action = "<CMD>wincmd j<CR>zz"; }
    { mode = "n"; key = "<C-k>"; action = "<CMD>wincmd k<CR>zz"; }
    { mode = "n"; key = "<C-l>"; action = "<CMD>wincmd l<CR>zz"; }
    { mode = "n"; key = "<C-d>"; action = "<C-d>zz"; }
    { mode = "n"; key = "<C-u>"; action = "<C-u>zz"; }
    { mode = "n"; key = "}"; action = "}zz"; }
    { mode = "n"; key = "{"; action = "{zz"; }

    # Send delete actions to black hole register
#   { mode = "n"; key = "D"; action = "\"_D"; }
#   { mode = "n"; key = "d"; action = "\"_d"; }
#   { mode = "n"; key = "\"*D"; action = "\"*D"; }
#   { mode = "n"; key = "\"*d"; action = "\"*d"; }

    ];

  };
         }
