_: {
  flake.modules.generic.nixvim =
    { lib, config, ... }:
    let
      inherit (config.mine.base) user;
    in
    {
      programs.nixvim = {
        opts = {
          # numbers
          relativenumber = true;
          nu = true;

          guicursor = "c-ci:hor10-iCursor-blinkwait300-blinkon200-blinkoff150,i:ver50-iCursor-blinkwait300-blinkon200-blinkoff150,n:ver10-block-blinkwait10-blinkon100-blinkoff150";
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
          undodir = "${user.homeDir}/.vim/undodir";

          hlsearch = true;
          incsearch = true;

          scrolloff = 8;
          signcolumn = "auto";
          list = true;
          listchars = "trail:·,extends:+,precedes:+";
        };
      };
    };
}
