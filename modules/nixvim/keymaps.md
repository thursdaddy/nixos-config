# NixVim Key Mappings

This file summarizes the custom and default key mappings for this NixVim configuration.

For a quick-reference guide of text objects, bracketed motions, and common editor shortcuts, see the companion [Cheat Sheet](file:///Users/thurs/projects/nix/nixos-config/modules/nixvim/cheatsheet.md).

---

### 🛠️ CUSTOM KEY MAPPINGS (NixVim Configuration)

This section lists mappings explicitly defined in `keymaps.nix` and `plugins.nix`.

### 🧭 Global & General Mappings

| Key | Action | Description |
| --- | --- | --- |
| `<leader>o` | `<CMD>only<CR>` | Close all window panes except active one |
| `<leader><C-o>` | `<CMD>%bd\|e#<CR>` | Delete all inactive buffers |
| `<leader>c` | `<CMD>noh<CR>` | Clear search match highlighting |
| `<C-d>` | `<C-d>zz` | Scroll half-page down and center cursor |
| `<C-u>` | `<C-u>zz` | Scroll half-page up and center cursor |
| `}` | `}zz` | Jump to next paragraph and center cursor |
| `{` | `{zz` | Jump to previous paragraph and center cursor |
| `<C-w>` | `<CMD>w!<CR>` | Force-save buffer |
| `<C-s>` | `ZZ` | Save and exit buffer |
| `<C-x>` | `ZQ` | Exit buffer without saving |
| `<C-o>` | `<CMD>bprev<CR>` | Jump to previous buffer |
| `<C-p>` | `<CMD>bnext<CR>` | Jump to next buffer |
| `<C-S-x>` | `<CMD>bdelete<CR>` | Delete current buffer |
| `d` / `D` | `"_d` / `"_D` | Delete to black hole register |
| `cc` / `C` | `dd` / `D` | Cut to default register |
| `"*d` / `"*D` | `"*d` / `"*D` | Delete to system register |
| `"*c` / `"*C` | `*dd` / `*D` | Cut to system register |

### 🐙 Git Mappings (`<leader>g...`)

| Key | Action / Command | Description |
| --- | --- | --- |
| `<leader>gs` | `<CMD>below Git<CR>` | Open Fugitive status split at the bottom |
| `<leader>gps` | `Snacks.picker.git_status()` | Open interactive status picker with live diff previews |
| `<leader>gd` | `Snacks.picker.git_diff()` | Open interactive diff view |
| `<leader>gl` | `Snacks.picker.git_log()` | Open interactive git commit log with previews |
| `<leader>gb` | `<CMD>Git blame<CR>` | Open vertical git blame split |
| `<leader>gc` | `<CMD>below Git<CR><CMD> vert Git commit<CR>` | Open status split and commit buffer |
| `<leader>ga` | `<CMD>Git add .<CR>` | Stage all unstaged changes |
| `<leader>gap` | `<CMD>Git add --patch<CR>` | Interactively stage changes (patch mode) |
| `<leader>gp` | `<CMD>Git push <bar> bd<CR>` | Push staged commits |
| `<leader>gpl` | `<CMD>Git pull<CR>` | Pull latest changes |
| `<leader>g,` | `<CMD>diffget //2<CR>` | Fetch diff target from LEFT side |
| `<leader>g.` | `<CMD>diffget //3<CR>` | Fetch diff target from RIGHT side |

### 🔍 Find Mappings (`<leader>f...`)

| Key | Action / Command | Description |
| --- | --- | --- |
| `<leader>ff` | `Snacks.picker.smart()` | Fuzzy find files in workspace (smart/frecency) |
| `<leader>fa` | `Snacks.picker.files()` | Fuzzy find all files in workspace (including hidden/ignored) |
| `<leader>fb` | `<CMD>Pick buffers<CR>` | Show a list of open buffers |
| `<leader>fh` | `<CMD>Pick oldfiles<CR>` | Show recently opened files (History) |
| `<leader>fs` | `<CMD>Pick grep pattern='<cword>'<CR>` | Grep for word currently under cursor |
| `<C-f>` | `Snacks.picker.grep()` | Live grep search project |
| `<leader>fg` | `Snacks.picker.grep()` | Live grep search project (alternative shortcut) |

### 👁️ View Mappings (`<leader>v...` & Tree)

| Key | Action / Command | Description |
| --- | --- | --- |
| `<leader>vd` | `<CMD>Trouble diagnostics toggle<CR>` | Toggle the Trouble diagnostics panel |
| `<leader>vl` | `<CMD>Trouble symbols toggle<CR>` | Toggle Trouble LSP symbols/outline sidebar |
| `<leader>vt` | `<CMD>TodoTrouble<CR>` | Toggle Trouble project TODO list panel |
| `<leader>vh` | `<CMD>SnacksNotifierShow<CR>` | Open scrollable floating log of notification history |
| `<leader>vs` | `Snacks.scratch()` | Toggle temporary scratchpad buffer |
| `<leader>vf` | `MiniFiles.open()` | Open inline mini.files drawer |
| `<leader>vdo` | `MiniDiff.toggle_overlay()` | Toggle inline MiniDiff overlay highlights |
| `<leader>vmd` | `<CMD>MarkdownPreview<CR>` | Open markdown preview in default web browser |
| `<leader>vmds` | `<CMD>MarkdownPreviewStop<CR>` | Stop current markdown preview process |
| `<leader>vc` | `_G.toggle_cheatsheet()` | Toggle custom cheatsheet float window |
| `<leader>e` | `<CMD>NvimTreeToggle<CR>` | Toggle the NvimTree sidebar |
| `<leader>E` | `<CMD>NvimTreeFocus<CR>` | Focus the NvimTree sidebar |

### 🛠️ Code Mappings (`<leader>c...`)

| Key | Action / Command | Description |
| --- | --- | --- |
| `<leader>cf` | `conform.format()` | Manually run code formatter on active buffer |

### 📓 Obsidian Notes (`<leader>n...`)

| Key | Action / Command | Description |
| --- | --- | --- |
| `<leader>nn` | `<CMD>ObsidianNew<CR>` | Create a new Obsidian note |
| `<leader>ns` | `<CMD>ObsidianSearch<CR>` | Search Obsidian notes (ripgrep) |
| `<leader>np` | `<CMD>ObsidianQuickSwitch<CR>` | Quick switch / open Obsidian notes |
| `<leader>nd` | `<CMD>ObsidianToday<CR>` | Open today's daily note |
| `<leader>no` | `<CMD>ObsidianOpen<CR>` | Open the current note in the Obsidian App |

### 🖥️ Window & Split Navigation

| Key | Action | Description |
| --- | --- | --- |
| `<M-h>` | `<CMD>TmuxNavigateLeft<CR>zz` | Go to left split/Tmux pane and center cursor |
| `<M-j>` | `<CMD>TmuxNavigateDown<CR>zz` | Go to bottom split/Tmux pane and center cursor |
| `<M-k>` | `<CMD>TmuxNavigateUp<CR>zz` | Go to top split/Tmux pane and center cursor |
| `<M-l>` | `<CMD>TmuxNavigateRight<CR>zz` | Go to right split/Tmux pane and center cursor |

---

## 🔌 DEFAULT PLUGIN MAPPINGS & COMMANDS

A summary of active defaults and helper commands provided by active plugins.

### 🔴 Gitsigns

| Command / Key | Action | Description |
| --- | --- | --- |
| `:Gitsigns stage_hunk` | `<leader>hs` | Stage the hunk under the cursor |
| `:Gitsigns reset_hunk` | `<leader>hr` | Reset the hunk under the cursor |
| `:Gitsigns stage_buffer` | `<leader>hS` | Stage all hunks in current buffer |
| `:Gitsigns undo_stage_hunk` | `<leader>hu` | Undo last staged hunk |
| `:Gitsigns reset_buffer` | `<leader>hR` | Reset all hunks in current buffer |
| `:Gitsigns preview_hunk` | `<leader>hp` | Preview hunk under the cursor in popup |
| `:Gitsigns blame_line` | `<leader>hb` | Inline blame line details under cursor |
| `:Gitsigns diffthis [target]` | `<leader>hd` / `<leader>hD` | Show hunk diff against index |
| - | `]c` | Jump to next git hunk |
| - | `[c` | Jump to previous git hunk |
| - | `<leader>td` | Toggle deleted lines virtual lines |

### 🐙 Fugitive (Internal mappings)

Inside the `:Git` status split:
*   `s` : Stage files/hunks under cursor
*   `u` : Unstage files/hunks under cursor
*   `cc` : Open commit panel
*   `g?` : Help sheet containing all mappings

### 🎯 Fzf-checkout (Commands)

| Command | Description |
| --- | --- |
| `:GBranches` | Switch, create, or delete Git branches |
| `:GStash` | Manage and apply stashes |
| `:GCommits` | View commits history |

### 🏷️ GitBlame (Commands)

| Command | Description |
| --- | --- |
| `:GitBlameToggle` | Toggle the virtual blame inline text |
| `:GitBlameEnable` | Enable inline blame |
| `:GitBlameDisable` | Disable inline blame |
| `:GitBlameOpenCommitURL` | Open current line commit in browser |
| `:GitBlameOpenFileURL` | Open current line file in browser |
| `:GitBlameCopyCommitURL` | Copy commit web URL |
| `:GitBlameCopyFileURL` | Copy file web URL |
| `:GitBlameCopySHA` | Copy SHA of current commit |

### 📂 mini.files

Within `mini.files` directory panel:
*   `<CR>` : Open the hovered file/folder
*   `-` or `<BS>` : Move up to parent directory
*   `q` / `gq` : Exit explorer
*   `g?` : Toggle help legend
*   `w` : Synchronize/save file edits (create, rename, delete files/folders)
*   `<leader>q` : Close/quit the explorer panel

### ➕ mini.diff

*   `]H` : Jump to next diff hunk
*   `[H` : Jump to previous diff hunk
*   `gh` : Perform visual hunk operations

### 💬 mini.comment (Commenting)

Smart commenting motions.
*   `gcc` : Toggle line comment on current line
*   `gbc` : Toggle block comment on current line
*   `gc{motion}` : Toggle line comment over motion (e.g. `gcip` for paragraph)
*   `gb{motion}` : Toggle block comment over motion
*   `gc` : Visual mode selection toggle line comment
*   `gb` : Visual mode selection toggle block comment

### 🥪 Sandwich (Surround actions)

*   `sa{motion/textobject}{char}` : Add surrounding `{char}` (e.g., `saiw(` surrounds word with parens)
*   `sd{char}` : Delete surrounding `{char}` (e.g., `sd(` deletes parens around cursor)
*   `sr{old}{new}` : Replace surrounding `{old}` with `{new}`
*   `is` / `as` : Inner / Around surroundings selection scope

### 🎨 Colorizer

| Command | Description |
| --- | --- |
| `:ColorizerToggle` | Toggle color highlighting in buffer |
| `:ColorizerReloadAllBuffers` | Reload and colorize all open buffers |

### 💬 Noice

| Command | Description |
| --- | --- |
| `:Noice` | Open Noice options / dashboard |
| `:Noice history` | View previous command output history |
| `:Noice dismiss` | Dismiss all active message widgets |

### 👻 Transparent

| Command | Description |
| --- | --- |
| `:TransparentToggle` | Toggle background transparency |

### 🔦 Illuminate

Highlight other instances of word under cursor.
*   `<A-n>` : Jump to next occurrence of word
*   `<A-p>` : Jump to previous occurrence of word

### 🍫 Snacks

| Command | Description |
| --- | --- |
| `:SnacksNotifierShow` | Show notification history list |
| `:SnacksScratch` | Toggle a temporary scratchpad buffer |

### 📡 Mark-Radar

*   Enhances Neovim standard marks (jump via `` ` `` or `'`) by highlighting mark positions within the visible window.

### ⚡ Flash (Motion/Search)

Provides fast, overlay-based jump motions.
*   `s` : Jump to matches in visible window
*   `S` : Jump using Treesitter nodes
*   `r` : Remote jump (perform action at jump target without moving cursor)
*   `R` : Treesitter search
*   `gs` : Search/jump in any visible window

### 📝 Todo Comments

*   `]t` : Jump to next TODO comment
*   `[t` : Jump to previous TODO comment
*   `:TodoQuickFix` : List all TODOs in project quickfix list
*   `:TodoTrouble` : View project TODOs in Trouble list pane