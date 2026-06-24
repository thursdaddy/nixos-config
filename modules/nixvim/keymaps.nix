_: {
  flake.modules.generic.nixvim = {
    programs.nixvim = {
      globals.mapleader = " ";

      keymaps = [
        # close panes
        {
          mode = "n";
          key = "<leader>o";
          action = "<CMD>only<CR>";
        }
        # delete all buffers but current
        {
          mode = "n";
          key = "<leader><C-o>";
          action = "<CMD>%bd|e#<CR>";
        }
        # clear highlights
        {
          mode = "n";
          key = "<leader>c";
          action = "<CMD>noh<CR>";
        }

        # keep things centered
        {
          mode = "n";
          key = "<C-d>";
          action = "<C-d>zz";
        }
        {
          mode = "n";
          key = "<C-u>";
          action = "<C-u>zz";
        }
        {
          mode = "n";
          key = "}";
          action = "}zz";
        }
        {
          mode = "n";
          key = "{";
          action = "{zz";
        }
        # quick save/exit
        {
          mode = "n";
          key = "<C-w>";
          action = "<CMD>w!<CR>";
        }
        {
          mode = "n";
          key = "<C-s>";
          action = "ZZ";
        }
        {
          mode = "n";
          key = "<C-x>";
          action = "ZQ";
        }

        # buffer nav
        {
          mode = "n";
          key = "<C-o>";
          action = "<CMD>bprev<CR>";
        }
        {
          mode = "n";
          key = "<C-p>";
          action = "<CMD>bnext<CR>";
        }
        {
          mode = "n";
          key = "<C-S-x>";
          action = "<CMD>bdelete<CR>";
        }

        # send delete actions to black hole register
        {
          mode = "n";
          key = "D";
          action = "\"_D";
        }
        {
          mode = "n";
          key = "d";
          action = "\"_d";
        }
        {
          mode = "n";
          key = "\"*D";
          action = "\"*D";
        }
        {
          mode = "n";
          key = "\"*d";
          action = "\"*d";
        }

        # cut without going into insert mode
        {
          mode = "n";
          key = "cc";
          action = "dd";
        }
        {
          mode = "n";
          key = "C";
          action = "D";
        }
        {
          mode = "n";
          key = "\"*C";
          action = "*D";
        }
        {
          mode = "n";
          key = "\"*c";
          action = "*dd";
        }
        {
          mode = "n";
          key = "<leader>vc";
          action = "<CMD>lua _G.toggle_cheatsheet()<CR>";
          options.desc = "Toggle Cheatsheet";
        }
      ];

      extraConfigLua = ''
        local cheatsheet_buf = nil
        local cheatsheet_win = nil

        _G.toggle_cheatsheet = function()
          if cheatsheet_win and vim.api.nvim_win_is_valid(cheatsheet_win) then
            vim.api.nvim_win_close(cheatsheet_win, true)
            cheatsheet_win = nil
            return
          end

          if not cheatsheet_buf or not vim.api.nvim_buf_is_valid(cheatsheet_buf) then
            cheatsheet_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_call(cheatsheet_buf, function()
              vim.cmd("read ${./cheatsheet.md}")
              vim.cmd("0d_") -- delete empty first line
            end)
            vim.bo[cheatsheet_buf].filetype = "markdown"
            vim.bo[cheatsheet_buf].modifiable = false
          end

          local width = math.floor(vim.o.columns * 0.95)
          local height = math.floor(vim.o.lines * 0.9)
          local col = math.floor((vim.o.columns - width) / 2)
          local row = math.floor((vim.o.lines - height) / 2)

          cheatsheet_win = vim.api.nvim_open_win(cheatsheet_buf, true, {
            relative = "editor",
            width = width,
            height = height,
            col = col,
            row = row,
            style = "minimal",
            border = "rounded",
          })
          
          vim.wo[cheatsheet_win].conceallevel = 2
          vim.wo[cheatsheet_win].concealcursor = "nc"
          
          vim.keymap.set('n', 'q', _G.toggle_cheatsheet, { buffer = cheatsheet_buf, noremap = true, silent = true })
          vim.keymap.set('n', '<Esc>', _G.toggle_cheatsheet, { buffer = cheatsheet_buf, noremap = true, silent = true })
        end
      '';
    };
  };
}
