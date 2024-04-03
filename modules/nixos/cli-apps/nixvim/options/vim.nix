{ lib, config, ... }:
with lib;
let
user = config.mine.user;
in
{
  programs.nixvim = {
    options = {
      # numbers
      relativenumber = true;
      nu = true;

      guicursor = "i-c-ci:hor10-iCursor-blinkwait300-blinkon200-blinkoff150,n:ver10-iCursor-blinkwait10-blinkon100-blinkoff150";

      # tabs
      shiftwidth = 2;
      expandtab = true;
      tabstop = 2;
      softtabstop = 2;

      autoindent = true;
      smartindent = true;

      swapfile = false;
      backup = false;
      undofile = true;
      undodir = mkIf (user.enable) "${user.homeDir}/.vim/undodir";
      updatetime = 2000;

      hlsearch = false;
      incsearch = true;

      scrolloff = 8;
      signcolumn = "auto";
      list = true;
      listchars = "lead:·,trail:·,eol:↲,extends:+,precedes:+";

    };

    highlight = {
      Comment.fg = "#708090";
      Comment.bg = "none";
      Comment.bold = true;

      Normal.bg = "none";
      Normal.ctermbg = "none";
      NonText.bg = "none";
      NonText.ctermbg = "none";
      NonText.fg = "#48494B";
      SpecialKey.fg = "#48494B";
      NvimTreeNormal.ctermbg = "none";
      NvimTreeNormal.bg = "none";
      NormalFloat.bg = "none";
      NormalFloat.ctermbg = "none";
      LineNr.bg = "none";
    };
  };

}

