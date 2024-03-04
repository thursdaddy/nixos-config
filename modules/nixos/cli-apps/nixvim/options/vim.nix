{ lib, config, ... }:
with lib;
let
user = config.mine.nixos.user;
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
      wrap = false;

      # disable swap, enable undorfile
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
      NonText.bg = "none";
      NonText.fg = "#48494B";
      SpecialKey.fg = "#48494B";
    };
  };

}

