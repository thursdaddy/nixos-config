{ ... }: {
  programs.nixvim = {
    plugins = {
      barbecue.enable = true;
      cmp-buffer.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      comment-nvim.enable = true;
      endwise.enable = true;
      fugitive.enable = true;
      gitgutter.enable = true;
      illuminate.enable = true;
      indent-blankline.enable = true;
      lastplace.enable = true;
      lsp-format.enable = true;
      luasnip.enable = true;
      noice.enable = true;
      surround.enable = true;
      tmux-navigator.enable = true;
      undotree.enable = true;
      auto-save = {
        enable = true;
        triggerEvents = [ "BufLeave" ];
      };
#     bufferline = {
#       enable = true;
#       diagnostics = "nvim_lsp";
#     };
      nvim-tree = {
        enable = true;
        view = {
          side = "right";
        };
      };
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          lua-ls = {
            enable = true;
            settings.telemetry.enable = false;
          };
          nixd = {
            enable = true;
            settings.formatting.command = "nixpkgs-fmt";
          };
          nil_ls.enable = true;
          terraformls.enable = true;
        };
      };
      lualine = {
        enable = true;
        theme = "onedark";
        sections = {
          lualine_c = [ "filename" ];
        };
      };
      notify = {
        enable = true;
        topDown = false;
        backgroundColour = "#000000";
        fps = 200;
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
          "<Tab>" = {
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
          "<S-Tab>" = {
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
      { mode = "n"; key = "<C-h>"; action = "<CMD>TmuxNavigateLeft<CR>zz"; }
      { mode = "n"; key = "<C-j>"; action = "<CMD>TmuxNavigateDown<CR>zz"; }
      { mode = "n"; key = "<C-k>"; action = "<CMD>TmuxNavigateUp<CR>zz"; }
      { mode = "n"; key = "<C-l>"; action = "<CMD>TmuxNavigateRight<CR>zz"; }
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
