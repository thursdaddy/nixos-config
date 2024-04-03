{ ... }: {

  programs.nixvim = {
    plugins = {
      cmp-buffer = { enable = true; };
      cmp-emoji = { enable = true; };
      cmp-nvim-lsp = { enable = true; };
      cmp-path = { enable = true; };
    };

    plugins.nvim-cmp = {
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
  };
}
