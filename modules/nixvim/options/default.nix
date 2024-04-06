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
      listchars = "trail:·,extends:+,precedes:+";

    };
  };
}
