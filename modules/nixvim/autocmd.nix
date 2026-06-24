_: {
  flake.modules.generic.nixvim = {
    programs.nixvim = {
      autoGroups = {
        highlight_yank = { };
        wscleanup = { };
      };

      autoCmd = [
        {
          event = "filetype";
          pattern = "minifiles";
          callback = {
            __raw = ''
              function(args)
                -- save/apply changes with <leader>w
                vim.keymap.set('n', 'w', function() require('mini.files').synchronize() end, { buffer = args.buf, desc = "sync mini.files" })
                -- quit/close the explorer with <leader>q
                vim.keymap.set('n', '<leader>q', function() require('mini.files').close() end, { buffer = args.buf, desc = "close mini.files" })
              end
            '';
          };
        }
        {
          group = "highlight_yank";
          event = "textyankpost";
          pattern = "*";
          callback = {
            __raw = "function() vim.highlight.on_yank { higroup = 'incsearch', timeout = 500 } end";
          };
        }
        {
          group = "wscleanup";
          event = "bufwritepre";
          pattern = "*";
          # replace the raw string command with a lua callback that checks the buffer type
          callback = {
            __raw = ''
              function()
                if vim.bo.buftype ~= "" then
                  return
                end
                -- save cursor position to prevent the screen from jumping
                local save = vim.fn.winsaveview()
                -- run the substitution silently
                vim.cmd([[%s/\s\+$//e]])
                -- restore cursor position
                vim.fn.winrestview(save)
              end
            '';
          };
        }
      ];
    };
  };
}
