_: {
  flake.modules.generic.nixvim =
    { lib, pkgs, ... }:
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
          colorful-menu.enable = true;
          conform-nvim = {
            enable = true;
            settings = {
              format_on_save = {
                lsp_fallback = true;
                timeout_ms = 500;
              };
              formatters_by_ft = {
                nix = [ "nixfmt" ];
                python = [
                  "isort"
                  "black"
                ];
                lua = [ "stylua" ];
              };
            };
          };
          colorizer.enable = true;
          direnv.enable = true;
          endwise.enable = true;
          flash.enable = true;
          fugitive.enable = true;
          gitsigns.enable = true;
          lazygit.enable = true;
          illuminate = {
            enable = true;
            settings = {
              providers = [
                "lsp"
                "treesitter"
                "regex"
              ];
            };
          };
          lastplace.enable = true;
          luasnip.enable = true;
          markdown-preview.enable = true;
          mark-radar.enable = true;
          mini = {
            enable = true;
            modules = {
              ai.enable = true;
              animate = {
                enable = true;
                scroll = {
                  timing = {
                    __raw = "require('mini.animate').gen_timing.linear({ duration = 100, unit = 'total' })";
                  };
                };
                cursor = {
                  timing = {
                    __raw = "require('mini.animate').gen_timing.linear({ duration = 50, unit = 'total' })";
                  };
                };
                open = {
                  enable = false;
                };
                close = {
                  enable = false;
                };
                resize = {
                  enable = false;
                };
              };
              bracketed.enable = true;
              clue = {
                enable = true;
                triggers = [
                  {
                    mode = "n";
                    keys = "<leader>";
                  }
                  {
                    mode = "x";
                    keys = "<leader>";
                  }
                  {
                    mode = "n";
                    keys = "g";
                  }
                  {
                    mode = "x";
                    keys = "g";
                  }
                  {
                    mode = "n";
                    keys = "`";
                  }
                  {
                    mode = "x";
                    keys = "`";
                  }
                  {
                    mode = "n";
                    keys = "\"";
                  }
                  {
                    mode = "x";
                    keys = "\"";
                  }
                  {
                    mode = "i";
                    keys = "<C-x>";
                  }
                  {
                    mode = "n";
                    keys = "<C-w>";
                  }
                  {
                    mode = "n";
                    keys = "[";
                  }
                  {
                    mode = "n";
                    keys = "]";
                  }
                ];
                clues = [
                  { __raw = "require('mini.clue').gen_clues.g()"; }
                  { __raw = "require('mini.clue').gen_clues.marks()"; }
                  { __raw = "require('mini.clue').gen_clues.registers()"; }
                  { __raw = "require('mini.clue').gen_clues.windows()"; }
                  { __raw = "require('mini.clue').gen_clues.z()"; }
                ];
              };
              comment.enable = true;
              completion = {
                enable = true;
                delay = {
                  completion = 300;
                  info = 100;
                  signature = 50;
                };
                fallback_action = "";
                window = {
                  info = {
                    border = "rounded";
                  };
                  signature = {
                    border = "rounded";
                  };
                };
              };
              diff.enable = true;
              extra.enable = true;
              git.enable = true;
              files.enable = true;
              icons.enable = true;
              indentscope = {
                enable = true;
                draw = {
                  delay = 30;
                  animation = {
                    __raw = "require('mini.indentscope').gen_animation.quadratic({ duration = 5, unit = 'step' })";
                  };
                };
              };
              jump2d.enable = true;
              pick = {
                enable = true;
                delay = {
                  async = 10;
                  busy = 50;
                };
                mappings = {
                  move_up = "<C-k>";
                  move_down = "<C-j>";
                  scroll_up = "<C-K>";
                  scroll_down = "<C-J>";
                };
                window = {
                  config = {
                    __raw = ''
                      function()
                        local height = math.floor(vim.o.lines * 0.45)
                        local width = math.floor(vim.o.columns * 0.6)
                        return {
                          anchor = 'NW',
                          height = height,
                          width = width,
                          row = math.floor((vim.o.lines - height) / 2),
                          col = math.floor((vim.o.columns - width) / 2),
                          relative = 'editor',
                          border = 'rounded',
                        }
                      end
                    '';
                  };
                };
              };
              pairs.enable = true;
              sessions.enable = true;
              splitjoin.enable = true;
              statusline = {
                enable = true;
                content = {
                  active = {
                    __raw = ''
                      function()
                        local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
                        local git           = MiniStatusline.section_git({ trunc_width = 75 })
                        local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 75 })

                        local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
                        local location      = MiniStatusline.section_location({ trunc_width = 75 })
                        local search        = MiniStatusline.section_searchcount({ trunc_width = 75 })

                        local reg_recording = vim.fn.reg_recording()
                        local macro = ""
                        if reg_recording ~= "" then
                          macro = "recording @" .. reg_recording
                        end

                        local lsp_names = {}
                        for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                          table.insert(lsp_names, client.name)
                        end
                        local lsp = table.concat(lsp_names, ", ")
                        if lsp ~= "" then lsp = "[" .. lsp .. "]" end

                        local left_sections = {}
                        table.insert(left_sections, string.format("%%#%s#%s", mode_hl, mode))
                        if macro ~= "" then
                          table.insert(left_sections, string.format("%%#MiniStatuslineMacro#❘ %s", macro))
                        end
                        if git and git ~= "" then
                          table.insert(left_sections, string.format("%%#MiniStatuslineGit#❘ %s", git))
                        end
                        if diagnostics and diagnostics ~= "" then
                          table.insert(left_sections, string.format("%%#MiniStatuslineDevinfo#%s", diagnostics))
                        end

                        local right_sections = {}
                        if lsp ~= "" then
                          table.insert(right_sections, string.format("%%#MiniStatuslineLSP# %s", lsp))
                        end
                        if search and search ~= "" then
                          table.insert(right_sections, string.format("%%#MiniStatuslineDevinfo#❘ %s", search))
                        end
                        if fileinfo and fileinfo ~= "" then
                          table.insert(right_sections, string.format("%%#MiniStatuslineFileinfo#❘ %s", fileinfo))
                        end
                        if location and location ~= "" then
                          table.insert(right_sections, string.format("%%#MiniStatuslineLocation#❘ %s", location))
                        end

                        local left = table.concat(left_sections, " ")
                        local right = table.concat(right_sections, " ")

                        return string.format(" %s %%<%%= %s ", left, right)
                      end
                    '';
                  };
                };
              };
              visits.enable = true;
            };
          };
          render-markdown.enable = true;
          sandwich.enable = true;
          snacks = {
            enable = true;
            settings = {
              dashboard = {
                enabled = true;
                sections = [
                  { section = "header"; }
                ];
              };
              picker = {
                matcher = {
                  frecency = true;
                  fuzzy = true;
                  smartcase = true;
                  ignorecase = true;
                  sort_empty = true;
                  history_bonus = true;
                };
              };
            };
          };
          tmux-navigator.enable = true;
          todo-comments.enable = true;
          web-devicons.enable = true;
          gitblame = {
            enable = true;
            settings = {
              delay = 4000;
            };
          };
          noice = {
            enable = true;
            settings = {
              lsp = {
                hover.enabled = false;
                signature.enabled = false;
              };
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
            settings = {
              update_focused_file = {
                enable = true;
              };
              view = {
                side = "right";
              };
            };
          };
          lsp = {
            enable = true;
            servers = {
              bashls.enable = true;
              gitlab_ci_ls.enable = true;
              jsonls.enable = true;
              jqls.enable = true;
              lua_ls = {
                enable = true;
                settings.telemetry.enable = false;
              };
              marksman.enable = true;
              nixd = {
                enable = true;
                settings = {
                  formatting.command = [ "nixfmt" ];
                  nixpkgs = {
                    expr = "import (builtins.getFlake (\"git+file://\" + builtins.toString ./.)).inputs.nixpkgs { }";
                  };
                  options = {
                    nixos.expr = "(builtins.getFlake (\"git+file://\" + builtins.toString ./.)).nixosConfigurations.homebox.options";
                    "nix-darwin".expr =
                      "(builtins.getFlake (\"git+file://\" + builtins.toString ./.)).darwinConfigurations.mbp.options";
                    "flake-parts".expr = "(builtins.getFlake (\"git+file://\" + builtins.toString ./.)).debug.options";
                  };
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

          notify = {
            settings = {
              background_colour = "Normal";
              enable = true;
              topDown = false;
              fps = 200;
              stages = "fade";
            };
          };
          obsidian = {
            enable = true;
            settings = {
              workspaces = [
                {
                  name = "thurs";
                  path = "~/notes/obsidian/thurs";
                }
              ];
              completion = {
                nvim_cmp = false;
                min_chars = 2;
              };
              picker = {
                name = "mini.pick";
              };
            };
          };

          treesitter = {
            enable = true;
            grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
              bash
              latex
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
          # git (Snacks Pickers)
          {
            mode = "n";
            key = "<leader>gps";
            action = "<CMD>lua Snacks.picker.git_status()<CR>";
            options.desc = "Snacks Git Status";
          }
          {
            mode = "n";
            key = "<leader>gd";
            action = "<CMD>lua Snacks.picker.git_diff()<CR>";
            options.desc = "Snacks Git Diff";
          }
          {
            mode = "n";
            key = "<leader>gl";
            action = "<CMD>lua Snacks.picker.git_log()<CR>";
            options.desc = "Snacks Git Log";
          }

          # git (Fugitive)
          {
            mode = "n";
            key = "<leader>ga";
            action = "<CMD>Git add .<CR>";
            options.noremap = true;
            options.desc = "Stage All Changes";
          }
          {
            mode = "n";
            key = "<leader>gap";
            action = "<CMD>Git add --patch<CR>";
            options.noremap = true;
            options.desc = "Stage Changes (Patch)";
          }
          {
            mode = "n";
            key = "<leader>gs";
            action = "<CMD>below Git<CR>";
            options.noremap = true;
            options.desc = "Git Status Pane";
          }
          {
            mode = "n";
            key = "<leader>gc";
            action = "<CMD>below Git<CR><CMD> vert Git commit<CR>";
            options.noremap = true;
            options.desc = "Git Commit Pane";
          }
          {
            mode = "n";
            key = "<leader>gp";
            action = "<CMD>Git push <bar> bd<CR>";
            options.noremap = true;
            options.desc = "Git Push";
          }
          {
            mode = "n";
            key = "<leader>gpl";
            action = "<CMD>Git pull<CR>";
            options.noremap = true;
            options.desc = "Git Pull";
          }
          {
            mode = "n";
            key = "<leader>gb";
            action = "<CMD>Git blame<CR>";
            options.noremap = true;
            options.desc = "Git Blame Outline";
          }
          {
            mode = "n";
            key = "<leader>g,";
            action = "<CMD>diffget //2<CR>";
            options.noremap = true;
            options.desc = "Diff Get Left (Ours)";
          }
          {
            mode = "n";
            key = "<leader>g.";
            action = "<CMD>diffget //3<CR>";
            options.noremap = true;
            options.desc = "Diff Get Right (Theirs)";
          }

          # find (Smart / All / History / Grep / Buffers)
          {
            mode = "n";
            key = "<leader>ff";
            action = "<CMD>lua Snacks.picker.smart()<CR>";
            options.desc = "Smart Search Files";
          }
          {
            mode = "n";
            key = "<leader>fa";
            action = "<CMD>lua Snacks.picker.files()<CR>";
            options.desc = "Search All Files";
          }
          {
            mode = "n";
            key = "<leader>fh";
            action = "<CMD>Pick oldfiles<CR>";
            options.desc = "Search History (Oldfiles)";
          }
          {
            mode = "n";
            key = "<leader>fs";
            action = "<CMD>Pick grep pattern='<cword>'<CR>";
            options.desc = "Grep Word Under Cursor";
          }
          {
            mode = "n";
            key = "<leader>fb";
            action = "<CMD>Pick buffers<CR>";
            options.desc = "Search Buffers";
          }
          {
            mode = "n";
            key = "<C-f>";
            action = "<CMD>lua Snacks.picker.grep()<CR>";
            options.desc = "Live Grep";
          }
          {
            mode = "n";
            key = "<leader>fg";
            action = "<CMD>lua Snacks.picker.grep()<CR>";
            options.desc = "Live Grep";
          }

          # view (Toggles / Previews / History)
          {
            mode = "n";
            key = "<leader>vd";
            action = "<CMD>Trouble diagnostics toggle<CR>";
            options.noremap = true;
            options.desc = "Toggle Diagnostics Panel";
          }
          {
            mode = "n";
            key = "<leader>vl";
            action = "<CMD>Trouble symbols toggle<CR>";
            options.desc = "Toggle LSP Outline Symbols";
          }
          {
            mode = "n";
            key = "<leader>vt";
            action = "<CMD>TodoTrouble<CR>";
            options.desc = "Toggle Project TODOs";
          }
          {
            mode = "n";
            key = "<leader>vh";
            action = "<CMD>SnacksNotifierShow<CR>";
            options.desc = "View Notification History";
          }
          {
            mode = "n";
            key = "<leader>vs";
            action = "<CMD>lua Snacks.scratch()<CR>";
            options.desc = "Toggle Scratchpad";
          }
          {
            mode = "n";
            key = "<leader>vf";
            action = "<CMD>lua MiniFiles.open()<CR>";
            options.desc = "Open Mini Files Drawer";
          }
          {
            mode = "n";
            key = "<leader>vdo";
            action = "<CMD>lua MiniDiff.toggle_overlay()<CR>";
            options.desc = "Toggle Mini Diff Overlay";
          }
          {
            mode = "n";
            key = "<leader>vmd";
            action = "<CMD>MarkdownPreview<CR>";
            options.desc = "Start Markdown Browser Preview";
          }
          {
            mode = "n";
            key = "<leader>vmds";
            action = "<CMD>MarkdownPreviewStop<CR>";
            options.desc = "Stop Markdown Browser Preview";
          }
          {
            mode = "n";
            key = "<leader>e";
            action = "<CMD>NvimTreeToggle<CR>";
            options.desc = "Toggle File Tree";
          }
          {
            mode = "n";
            key = "<leader>E";
            action = "<CMD>NvimTreeFocus<CR>";
            options.desc = "Focus File Tree";
          }

          # code (Actions / Format)
          {
            mode = "n";
            key = "<leader>cf";
            action = "<CMD>lua require('conform').format({ async = true, lsp_fallback = true })<CR>";
            options.desc = "Format Code Buffer";
          }

          # obsidian notes
          {
            mode = "n";
            key = "<leader>nn";
            action = "<CMD>ObsidianNew<CR>";
            options.desc = "New Obsidian Note";
          }
          {
            mode = "n";
            key = "<leader>ns";
            action = "<CMD>ObsidianSearch<CR>";
            options.desc = "Search Obsidian Notes";
          }
          {
            mode = "n";
            key = "<leader>np";
            action = "<CMD>ObsidianQuickSwitch<CR>";
            options.desc = "Quick Switch Notes";
          }
          {
            mode = "n";
            key = "<leader>nd";
            action = "<CMD>ObsidianToday<CR>";
            options.desc = "Obsidian Today's Note";
          }
          {
            mode = "n";
            key = "<leader>no";
            action = "<CMD>ObsidianOpen<CR>";
            options.desc = "Open in Obsidian App";
          }

          # tmux navigation
          {
            mode = "n";
            key = "<M-h>";
            action = "<CMD>TmuxNavigateLeft<CR>zz";
          }
          {
            mode = "n";
            key = "<M-j>";
            action = "<CMD>TmuxNavigateDown<CR>zz";
          }
          {
            mode = "n";
            key = "<M-k>";
            action = "<CMD>TmuxNavigateUp<CR>zz";
          }
          {
            mode = "n";
            key = "<M-l>";
            action = "<CMD>TmuxNavigateRight<CR>zz";
          }
        ];

        extraConfigVim = lib.mkIf pkgs.stdenv.isDarwin ''
          let g:fugitive_git_executable = "${lib.getExe' pkgs.darwinGit "git"}"
        '';

        extraConfigLua = ''
          vim.api.nvim_create_autocmd('FileType', {
            pattern = 'snacks_picker_input',
            callback = function()
              vim.b.minicompletion_disable = true
            end,
          })

          vim.keymap.set('i', '<C-j>', function()
            return vim.fn.pumvisible() == 1 and '<C-n>' or '<C-j>'
          end, { expr = true, replace_keycodes = true })

          vim.keymap.set('i', '<C-k>', function()
            return vim.fn.pumvisible() == 1 and '<C-p>' or '<C-k>'
          end, { expr = true, replace_keycodes = true })

          -- Fix transparent-nvim not clearing nvim-notify backgrounds
          require('transparent').setup({
            extra_groups = {
              "NotifyBackground",
              "NotifyFloat",
            }
          })
          vim.api.nvim_create_autocmd("ColorScheme", {
            pattern = "*",
            callback = function()
              vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "none" })
            end,
          })

        '';

        extraPlugins = with pkgs; [
          fzf-checkout
          unstable.vimPlugins.transparent-nvim
          unstable.vimPlugins.vim-shellcheck
          unstable.vimPlugins.vim-just
          unstable.vimPlugins.vim-rhubarb
          vimPlugins.fzfWrapper
        ];
      };
    };
}
