{ ... }: {
  programs.nixvim = {
    globals.mapleader = " ";

    keymaps = [
      # keep things centered
      { mode = "n"; key = "<C-d>"; action = "<C-d>zz"; }
      { mode = "n"; key = "<C-u>"; action = "<C-u>zz"; }
      { mode = "n"; key = "}"; action = "}zz"; }
      { mode = "n"; key = "{"; action = "{zz"; }

      { mode = "n"; key = "<C-s>"; action = "ZZ"; }
      { mode = "n"; key = "<C-x>"; action = "ZQ"; }
      { mode = "n"; key = "<C-o>"; action = "<CMD>bprev<CR>"; }
      { mode = "n"; key = "<C-p>"; action = "<CMD>bnext<CR>"; }
      { mode = "n"; key = "<C-S-x>"; action = "<CMD>bdelete<CR>"; }

      # send delete actions to black hole register
      { mode = "n"; key = "D"; action = "\"_D"; }
      { mode = "n"; key = "d"; action = "\"_d"; }
      { mode = "n"; key = "\"*D"; action = "\"*D"; }
      { mode = "n"; key = "\"*d"; action = "\"*d"; }

      # cut without going into insert mode
      { mode = "n"; key = "cc"; action = "dd"; }
      { mode = "n"; key = "C"; action = "D"; }
      { mode = "n"; key = "\"*C"; action = "*D"; }
      { mode = "n"; key = "\"*c"; action = "*dd"; }
    ];
  };
}
