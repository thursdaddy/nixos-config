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

      guicursor = "";

      # tabs
      shiftwidth = 2;
      expandtab = true;
      tabstop = 2;
      softtabstop = 2;

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

    };

    match.ExtraWhitespace = "\\s\\+$";

    highlight = {
     Comment.fg = "#708090";
     Comment.bg = "none";
     Comment.bold = true;
     ExtraWhitespace.bg = "#708090";
    };
  };

}

