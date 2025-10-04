{ pkgs, ... }:
let

  fzf-checkout = pkgs.vimUtils.buildVimPlugin {
    name = "fzf-checkout";
    src = pkgs.fetchFromGitHub {
      owner = "stsewd";
      repo = "fzf-checkout.vim";
      rev = "db0289a6c8e77b08a0150627733722fd07d5fa62";
      hash = "sha256-lM5vv0ucgxvoc8ZtJwShDoY7ji6BYl6VZA2bYN0UU2s=";
    };
  };

in
{
  programs.nixvim = {
    plugins = {
      barbecue.enable = true;
      cmp-buffer.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      comment.enable = true;
      diffview.enable = true;
      direnv.enable = true;
      endwise.enable = true;
      fugitive.enable = true;
      gitgutter.enable = false;
      gitsigns.enable = true;
      illuminate.enable = true;
      indent-blankline.enable = true;
      lastplace.enable = true;
      lsp-format.enable = true;
      luasnip.enable = true;
      markdown-preview.enable = true;
      snacks.enable = true;
      tmux-navigator.enable = true;
      undotree.enable = true;
      vim-surround.enable = true;
      web-devicons.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "buffer"; }
            { name = "nvim_lua"; }
            { name = "path"; }
          ];
          snippet = {
            expand = "luasnip";
          };
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
          };
        };
      };
      gitblame = {
        enable = true;
        settings = {
          delay = 4000;
        };
      };
      noice = {
        enable = true;
        settings = {
          presets = {
            bottom_search = true;
            long_message_to_split = true;
          };
          routes = [
            {
              view = "notify";
              filter = {
                event = "msg_showmode";
              };
            }
            {
              view = "cmdline_output";
              filter = {
                event = "msg_show";
                min_height = 15;
              };
            }
          ];
        };
      };
      nvim-tree = {
        enable = true;
        updateFocusedFile = {
          enable = true;
        };
        view = {
          side = "right";
        };
      };
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          harper_ls.enable = true;
          jsonls.enable = true;
          lua_ls = {
            enable = true;
            settings.telemetry.enable = false;
          };
          marksman.enable = true;
          nil_ls = {
            enable = true;
            settings = {
              formatting.command = [ "nixfmt" ];
            };
          };
          pylsp = {
            enable = true;
            settings.plugins = {
              black.enabled = true; # code formatter
              # code style enforcement
              flake8 = {
                enabled = true;
                autoArchive = true;
                autoEvalInputs = true;
                ignore = [
                  "E302"
                  "E305"
                  "E501"
                  "W503"
                ];
              };
              isort.enabled = true; # import sort
              jedi.enabled = true; # autocompletion
              mccabe.enabled = true; # code complexity checker
              pylint.enabled = true;
            };
          };
          terraformls.enable = true;
          yamlls.enable = true;
        };
      };
      lualine = {
        enable = true;
        settings = {
          options.theme = "nord";
          sections = {
            lualine_c = [ "filename" ];
          };
        };
      };
      notify = {
        settings = {
          enable = true;
          topDown = false;
          fps = 200;
          stages = "fade";
          backgroundColour = "#000000";
        };
      };
      telescope = {
        enable = true;
        highlightTheme = "ivy";
        extensions = {
          fzf-native.enable = true;
          frecency.enable = true;
          undo.enable = true;
        };
        keymaps = {
          "<leader>fb" = "buffers";
          "<leader>fd" = "diagnostics";
          "<leader>fh" = "oldfiles";
          "<leader>fs" = "grep_string";
          "<leader>fu" = "undo";

          "<C-f>" = "live_grep";

          "<leader>fg" = "git_files";
          "<leader>fgb" = "git_branches";
          "<leader>fgs" = "git_stash";
          "<leader>fgc" = "git_commits";
          "<leader>fbc" = "git_bcommits";
        };
      };
      treesitter = {
        enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          latex
          norg
          tsx
          typst
          vue
          lua
          markdown
          nix
          python
          javascript
          typescript
          dockerfile
          json
          toml
          yaml
          vim
          vimdoc
          tmux
          regex
          gitcommit
          gitignore
        ];
      };
      trouble.enable = true;
    };
    # plugin specific keymaps
    keymaps = [
      # diff-view
      {
        mode = "n";
        key = "<leader>dv";
        action = "<CMD>DiffviewOpen<CR>";
      }
      {
        mode = "n";
        key = "<leader>dvh";
        action = "<CMD>DiffviewFileHistory<CR>";
      }
      {
        mode = "n";
        key = "<leader>dvc";
        action = "<CMD>DiffviewClose<CR>";
      }
      # telescope
      {
        mode = "n";
        key = "<leader>ff";
        action = "<CMD>Telescope find_files find_command=rg,--no-ignore,--files,--hidden,--glob,!.git,--glob,!.terraform prompt_prefix=🔍<CR>";
      }
      # tmux-navigator
      {
        mode = "n";
        key = "<C-h>";
        action = "<CMD>TmuxNavigateLeft<CR>zz";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<CMD>TmuxNavigateDown<CR>zz";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<CMD>TmuxNavigateUp<CR>zz";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<CMD>TmuxNavigateRight<CR>zz";
      }
      # markdown-preview
      {
        mode = "n";
        key = "<leader>md";
        action = "<CMD>MarkdownPreview<CR>";
      }
      {
        mode = "n";
        key = "<leader>mds";
        action = "<CMD>MarkdownPreviewStop<CR>";
      }
      # nvim-tree
      {
        mode = "n";
        key = "<leader>e";
        action = "<CMD>NvimTreeToggle<CR>";
      }
      {
        mode = "n";
        key = "<leader>E";
        action = "<CMD>NvimTreeFocus<CR>";
      }
      # fugitive
      {
        mode = "n";
        key = "<leader>gaa";
        action = "<CMD>Git add .<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>gap";
        action = "<CMD>Git add --patch<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>gs";
        action = "<CMD>below Git<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<CMD>below Git commit<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>gb";
        action = "<CMD>GBranches<CR>";
        options.noremap = true;
      } # fzf-checkout
      {
        mode = "n";
        key = "<leader>gp";
        action = "<CMD>Git push<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>gl";
        action = "<CMD>Git pull<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>gcb";
        action = "<CMD>Git blame<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>g,";
        action = "<CMD>diffget //2<CR>";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>g.";
        action = "<CMD>diffget //3<CR>";
        options.noremap = true;
      }
      # vGit
      {
        mode = "n";
        key = "<leader>gdv";
        action = "<CMD>VGit project_diff_preview<CR>";
        options.noremap = true;
      }
      # Trouble
      {
        mode = "n";
        key = "<leader>vd";
        action = "<CMD>Trouble diagnostics toggle<CR>";
        options.noremap = true;
      }
    ];

    extraPlugins = with pkgs; [
      fzf-checkout
      unstable.vimPlugins.transparent-nvim
      unstable.vimPlugins.vim-shellcheck
      unstable.vimPlugins.vim-just
      unstable.vimPlugins.vim-rhubarb
      vimPlugins.fzfWrapper
    ];
  };
}
