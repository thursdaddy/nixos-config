{ ... }: {
  programs.nixvim = {
    plugins = {
      auto-save.enable = true;
      cmp-buffer.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      comment-nvim.enable = true;
      fugitive.enable = true;
      gitsigns.enable = true;
      indent-blankline.enable = true;
      lsp.enable = true;
      lsp-format.enable = true;
      luasnip.enable = true;
      surround.enable = true;
      undotree.enable = true;
      lualine = {
        enable = true;
        theme = "onedark";
        sections = {
          lualine_c = [ "filename" ];
        };
      };
      nvim-cmp = {
        enable = true;
        autoEnableSources = true;
        snippet = { expand = "luasnip"; };

        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "buffer"; }
          { name = "nvim_lua"; }
          { name = "path"; }
        ];

        mapping = {
          # This needs to be updated, re-watch TJ's kickstart re-vamp video
          "<CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })";
          "<C-n>" = {
            modes = [ "i" "s" ];
            action =
              # lua
              ''
              function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
                  elseif require("luasnip").expand_or_jumpable() then
                  vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
              else
                fallback()
                  end
                  end
              '';
          };
          "<C-p>" = {
            modes = [ "i" "s" ];
            action =
              # lua
              ''
              function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
                  elseif require("luasnip").jumpable(-1) then
                  vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
              else
                fallback()
                  end
                  end
              '';
          };
        };
      };
      nvim-tree = {
        enable = true;

      };
      telescope = {
        enable = true;
        highlightTheme = "ivy";
        defaults = { ## these dont seem to be working but arent breaking anything
          layout_strategy = "horizontal";
          layout_config = {
            height = 0.85;
            width = 0.75;
            prompt_position = "bottom";
          };
        };
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fb" = "buffers";
          "<leader>fs" = "grep_string";
          "<leader>fh" = "oldfiles";
          "<C-f>" = "live_grep";

          "<leader>fg" = "git_files";
          "<leader>fgb" = "git_branches";
          "<leader>fgs" = "git_stash";
          "<leader>fgc" = "git_commits";
          "<leader>fbc" = "git_bcommits";
        };
      };
    };
    # plugin specific keymaps
    keymaps = [
      # nvim-tree
      { mode = "n"; key = "<leader>e"; action = "<CMD>NvimTreeToggle<CR>"; }
      { mode = "n"; key = "<leader>E"; action = "<CMD>NvimTreeFocus<CR>"; }
      # fugitive
      { mode = "n"; key = "<leader>gs"; action = "<CMD>below Git<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gc"; action = "<CMD>below Git commit<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gb"; action = "<CMD>GBranches<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gp"; action = "<CMD>Git push<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gl"; action = "<CMD>Git pull<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gcb"; action = "<CMD>Git blame<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>g,"; action = "<CMD>diffget //2<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>g."; action = "<CMD>diffget //3<CR>"; options.noremap = true; }
    ];
  };
}
