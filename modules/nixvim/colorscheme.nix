_: {
  flake.modules.generic.nixvim =
    { pkgs, ... }:
    {
      programs.nixvim = {
        extraPlugins = [ pkgs.vimPlugins.gruvbox-nvim ];
        extraConfigLua = ''
          vim.o.background = "dark"
          require("gruvbox").setup({
              transparent_mode = true,
          })
          vim.cmd("colorscheme gruvbox")

          local custom_highlights = {
            -- StatusLine
            StatusLine = { bg = 'none' },
            StatusLineNC = { bg = 'none' },
            MiniStatuslineModeNormal = { fg = '#fabd2f', bg = 'none', bold = true },
            MiniStatuslineModeInsert = { fg = '#b8bb26', bg = 'none', bold = true },
            MiniStatuslineModeVisual = { fg = '#d3869b', bg = 'none', bold = true },
            MiniStatuslineModeReplace = { fg = '#fb4934', bg = 'none', bold = true },
            MiniStatuslineModeCommand = { fg = '#fe8019', bg = 'none', bold = true },
            MiniStatuslineModeOther = { fg = '#8ec07c', bg = 'none', bold = true },
            MiniStatuslineDevinfo = { fg = '#fe8019', bg = 'none' },
            MiniStatuslineFilename = { fg = '#ebdbb2', bg = 'none', bold = true },
            MiniStatuslineFileinfo = { fg = '#d3869b', bg = 'none' },
            MiniStatuslineLocation = { fg = '#83a598', bg = 'none' },
            MiniStatuslineGit = { fg = '#b8bb26', bg = 'none' },
            MiniStatuslineMacro = { fg = '#fb4934', bg = 'none', bold = true },
            MiniStatuslineLSP = { fg = '#8ec07c', bg = 'none' },
            MiniStatuslineInactive = { fg = '#928374', bg = 'none' },

            -- Snacks
            SnacksDashboardHeader = { fg = '#fabd2f' },

            -- Properties and Attributes
            ['nixAttribute'] = { link = 'GruvboxBlue' },
            ['nixAttributeDefinition'] = { link = 'GruvboxBlue' },
            ['nixAttributeAssignment'] = { fg = '#fabd2f' },
            ['nixAttributeDot'] = { link = 'GruvboxFg1' },
            ['@property'] = { link = 'GruvboxBlue' },
            ['@property.nix'] = { link = 'GruvboxBlue' },
            ['@variable.member'] = { link = 'GruvboxBlue' },
            ['@lsp.type.property.nix'] = { link = 'GruvboxBlue' },
            ['@lsp.type.variable.nix'] = { link = 'GruvboxBlue' },

            -- Keywords and Builtins
            ['nixLetExprKeyword'] = { link = 'GruvboxRed' },
            ['nixSimpleBuiltin'] = { link = 'GruvboxOrange' },
            ['@include'] = { link = 'GruvboxOrange' },
            ['@keyword.import'] = { link = 'GruvboxOrange' },

            -- Literals and Identifiers
            ['nixInteger'] = { link = 'GruvboxAqua' },
            ['nixFunctionCall'] = { link = 'GruvboxFg1' },
            ['nixLetExpr'] = { link = 'GruvboxFg1' },

            -- Operators
            ['nixOperator'] = { link = 'GruvboxOrange' },

            -- Delimiters, Brackets, and Punctuation
            ['nixInterpolationDelimiter'] = { fg = '#fabd2f' },
            ['nixPathDelimiter'] = { link = 'GruvboxOrange' },
            ['nixStringDelimiter'] = { link = 'GruvboxOrange' },
            ['nixArgumentSeparator'] = { link = 'GruvboxOrange' },
            ['@punctuation.bracket'] = { link = 'GruvboxFg1' },
            ['@punctuation.delimiter'] = { fg = '#fabd2f' },
            ['@punctuation.special'] = { fg = '#fabd2f' },
            ['@punctuation.bracket.nix'] = { link = 'GruvboxFg1' },
            ['TSPunctBracket'] = { link = 'GruvboxFg1' },
            ['TSPunctDelimiter'] = { fg = '#fabd2f' },
            ['TSPunctSpecial'] = { fg = '#fabd2f' },
            ['Delimiter'] = { link = 'GruvboxFg1' },
            ['nixParen'] = { link = 'GruvboxFg1' },
            ['nixList'] = { link = 'GruvboxFg1' },
            ['nixListBracket'] = { link = 'GruvboxFg1' },
            ['nixAttributeSet'] = { link = 'GruvboxFg1' },
            ['nixFunctionArgument'] = { link = 'GruvboxFg1' },

            -- Todo Comments (Plugin)
            ['TodoBgTODO'] = { fg = '#282828', bg = '#fabd2f', bold = true },
            ['TodoFgTODO'] = { fg = '#fabd2f' },
            ['TodoBgFIX'] = { fg = '#282828', bg = '#fb4934', bold = true },
            ['TodoFgFIX'] = { fg = '#fb4934' },
            ['TodoBgWARN'] = { fg = '#282828', bg = '#fe8019', bold = true },
            ['TodoFgWARN'] = { fg = '#fe8019' },
            ['TodoBgHACK'] = { fg = '#282828', bg = '#fe8019', bold = true },
            ['TodoFgHACK'] = { fg = '#fe8019' },
            ['TodoBgNOTE'] = { fg = '#282828', bg = '#8ec07c', bold = true },
            ['TodoFgNOTE'] = { fg = '#8ec07c' },
            ['TodoBgPERF'] = { fg = '#282828', bg = '#d3869b', bold = true },
            ['TodoFgPERF'] = { fg = '#d3869b' },

            -- Illuminated Word (Plugin)
            ['IlluminatedWordText'] = { link = 'GruvboxOrange' },
            ['IlluminatedWordRead'] = { link = 'GruvboxOrange' },
            ['IlluminatedWordWrite'] = { link = 'GruvboxOrange' },
          }

          local function apply_custom_highlights()
            for group, colors in pairs(custom_highlights) do
              vim.api.nvim_set_hl(0, group, colors)
            end
          end

          vim.api.nvim_create_autocmd('ColorScheme', {
            pattern = "*",
            callback = apply_custom_highlights,
          })
          apply_custom_highlights()
        '';
      };
    };
}
