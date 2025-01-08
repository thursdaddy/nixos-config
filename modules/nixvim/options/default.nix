{ lib, config, ... }:
with lib;
let
  inherit (config.mine) user;
in
{
  programs.nixvim = {
    opts = {
      # numbers
      relativenumber = true;
      nu = true;

      guicursor = "i-c-ci:hor10-iCursor-blinkwait300-blinkon200-blinkoff150,n:ver10-iCursor-blinkwait10-blinkon100-blinkoff150";
      termguicolors = true;

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
      undodir = mkIf user.enable "${user.homeDir}/.vim/undodir";

      hlsearch = true;
      incsearch = true;

      scrolloff = 8;
      signcolumn = "auto";
      list = true;
      listchars = "trail:·,extends:+,precedes:+";
    };
  };
}
