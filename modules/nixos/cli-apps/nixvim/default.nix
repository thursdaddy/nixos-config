{ lib, config, pkgs, inputs,  ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.nixos.nixvim;

  in {
      options.mine.nixos.nixvim = {
          enable = mkEnableOption "NixVim";
      };

      imports = [ inputs.nixvim.nixosModules.nixvim ];

      config = mkIf cfg.enable {

        programs.nixvim = {
            enable = true;
            colorschemes.onedark.enable = true;

            options = {
              shiftwidth = 2;
              number = true;
              relativenumber = true;
            };

            highlight = {
             Comment.fg = "#708090";
             Comment.bg = "none";
             Comment.bold = true;
            };

            plugins = {
                lualine = { enable = true; };
                nvim-tree = { enable = true; };
                luasnip = { enable = true; };
                cmp-buffer  = { enable = true; };
                cmp-emoji  = { enable = true; };
                cmp-nvim-lsp  = { enable = true; };
                cmp-path = { enable = true; };
            };

            plugins.lsp = {
              enable = true;

              servers = {
                nil_ls.enable = true;
                bashls.enable = true;

                lua-ls = {
                  enable = true;
                  settings.telemetry.enable = false;
                };

              };
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

            extraPlugins = with pkgs.vimPlugins; [
              { plugin = comment-nvim; config = "lua require(\"Comment\").setup()";}
            ];

            globals.mapleader = " ";

        };
      };

}
