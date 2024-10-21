{ pkgs, ... }: {
  programs.nixvim = {
    plugins = {
      barbecue.enable = true;
      cmp-buffer.enable = true;
      cmp-emoji.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      comment.enable = true;
      endwise.enable = true;
      fugitive.enable = true;
      gitgutter.enable = true;
      illuminate.enable = true;
      indent-blankline.enable = true;
      lastplace.enable = true;
      lsp-format.enable = true;
      luasnip.enable = true;
      surround.enable = true;
      tmux-navigator.enable = true;
      undotree.enable = true;
      auto-save = {
        enable = true;
        triggerEvents = [ "BufLeave" ];
      };
      diffview = {
        enable = true;
      };
      gitblame = {
        enable = true;
        delay = 4000;
      };
      noice = {
        enable = true;
        routes = [
          {
            view = "notify";
            filter = {
              event = "msg_showmode";
            };
          }
        ];
      };
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
          jsonls.enable = true;
          lua-ls = {
            enable = true;
            settings.telemetry.enable = false;
          };
          marksman.enable = true;
          nil-ls = {
            enable = true;
            settings = {
              formatting.command = [ "nixpkgs-fmt" ];
            };
          };
          pylsp = {
            enable = true;
            settings.plugins = {
              black.enabled = false; # code formatter
              # code style enforcement
              flake8 = {
                enabled = true;
                ignore = [ "E302" "E305" "E501" ];
              };
              isort.enabled = true; # import sort
              jedi.enabled = true; # autocompletion
              mccabe.enabled = true; # code complexity checker
              pycodestyle = {
                enabled = true;
                ignore = [ "E302" "E305" "E501" ];
              };
              pydocstyle = {
                enabled = true;
                ignore = [ "D400" "D415" ];
              };
              pylint.enabled = true;
            };
          };
          terraformls.enable = true;
          yamlls.enable = true;
        };
      };
      lualine = {
        enable = true;
        theme = "nord";
        sections = {
          lualine_c = [ "filename" ];
        };
      };
      notify = {
        enable = true;
        topDown = false;
        fps = 200;
        stages = "fade";
        backgroundColour = "#000000";
      };
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
          snippet = { expand = "luasnip"; };
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
      # render-markdown.enable = true; # not ready atm
      telescope = {
        enable = true;
        highlightTheme = "ivy";
        settings = {
          defaults = {
            ## these dont seem to be working but arent breaking anything
            layout_strategy = "horizontal";
            layout_config = {
              height = 0.85;
              width = 0.75;
              prompt_position = "bottom";
            };
          };
        };
        keymaps = {
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
      # diff-view
      { mode = "n"; key = "<leader>dv"; action = "<CMD>DiffviewOpen<CR>"; }
      { mode = "n"; key = "<leader>dvh"; action = "<CMD>DiffviewFileHistory<CR>"; }
      { mode = "n"; key = "<leader>dvc"; action = "<CMD>DiffviewClose<CR>"; }
      # telescope
      { mode = "n"; key = "<leader>ff"; action = "<CMD>Telescope find_files find_command=rg,--no-ignore,--files,--hidden,--glob,!.git,--glob,!.terraform prompt_prefix=🔍<CR>"; }
      # tmux-navigator
      { mode = "n"; key = "<C-h>"; action = "<CMD>TmuxNavigateLeft<CR>zz"; }
      { mode = "n"; key = "<C-j>"; action = "<CMD>TmuxNavigateDown<CR>zz"; }
      { mode = "n"; key = "<C-k>"; action = "<CMD>TmuxNavigateUp<CR>zz"; }
      { mode = "n"; key = "<C-l>"; action = "<CMD>TmuxNavigateRight<CR>zz"; }
      # nvim-tree
      { mode = "n"; key = "<leader>e"; action = "<CMD>NvimTreeToggle<CR>"; }
      { mode = "n"; key = "<leader>E"; action = "<CMD>NvimTreeFocus<CR>"; }
      # fugitive
      { mode = "n"; key = "<leader>gaa"; action = "<CMD>Git add .<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gs"; action = "<CMD>below Git<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gc"; action = "<CMD>below Git commit<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gb"; action = "<CMD>GBranches<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gp"; action = "<CMD>Git push<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gl"; action = "<CMD>Git pull<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>gcb"; action = "<CMD>Git blame<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>g,"; action = "<CMD>diffget //2<CR>"; options.noremap = true; }
      { mode = "n"; key = "<leader>g."; action = "<CMD>diffget //3<CR>"; options.noremap = true; }
    ];

    extraPlugins = with pkgs.unstable.vimPlugins; [
      transparent-nvim
      vim-shellcheck
    ];
  };
}
