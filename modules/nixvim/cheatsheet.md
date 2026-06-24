# NixVim Cheat Sheet

A quick-reference cheat sheet for Neovim motions, text objects, and shortcuts.

---

## 🧩 `mini.ai` Text Objects

Use in **Visual** (`v`) or **Operator-pending** mode (`d`/`y`/`c`).

*   **Syntax**: `[operator] + [a/i] + [identifier]`
    *   `a` : **Around** (includes surrounding delimiters/whitespace)
    *   `i` : **Inner** (only the contents inside)
*   **Next/Last Objects**:
    *   `an` / `in` : Target the **next** text object of that type
    *   `al` / `il` : Target the **previous (last)** text object of type
*   **Edge Motions**:
    *   `g[` : Jump to the **left edge** of the text object
    *   `g]` : Jump to the **right edge** of the text object

| Key | Text Object | Examples / Explanation |
| :---: | :--- | :--- |
| **`b`** | Balanced Brackets | Parentheses `()`, brackets `[]`, braces `{}`. e.g., `dib` (delete inside brackets). |
| **`q`** | Balanced Quotes | Quotes `'`, `"`, `` ` ``. e.g., `caq` (change around quotes). |
| **`f`** | Function Call | Selects function call with its arguments. e.g., `vif` (select function interior). |
| **`a`** | Argument | Comma-separated argument in a list. e.g., `daa` (delete around argument). |
| **`t`** | HTML/XML Tag | HTML/XML tags. e.g., `cit` (change inside tag like `<div>...</div>`). |
| **`d`** | Digits | Matches one or more digits. e.g., `vid` (select number). |
| **`?`** | User Prompt | Prompts you to enter a single character to use as the delimiter. |

---

## 🔀 `mini.bracketed` Motions

Jump backward (`[`) or forward (`]`) through various code elements.

*   **Syntax**:
    *   `[` + **lowercase** = Previous element
    *   `]` + **lowercase** = Next element
    *   `[` + **uppercase** = First element (beginning of buffer)
    *   `]` + **uppercase** = Last element (end of buffer)

| Suffix | Target | Keybindings | Description |
| :---: | :--- | :---: | :--- |
| **`b`** | Buffers | `[b` / `]b` (`[B` / `]B`) | Jump to previous/next (first/last) buffer |
| **`c`** | Comments | `[c` / `]c` (`[C` / `]C`) | Jump to previous/next (first/last) comment block |
| **`d`** | Diagnostics | `[d` / `]d` (`[D` / `]D`) | Jump to previous/next (first/last) LSP diagnostic |
| **`f`** | Files | `[f` / `]f` (`[F` / `]F`) | Jump to previous/next file path in directory |
| **`H`** | Git Hunks | `[H` / `]H` | Jump to previous/next git diff hunk (via `mini.diff`) |
| **`i`** | Indentation | `[i` / `]i` (`[I` / `]I`) | Jump to previous/next line with different indent level |
| **`j`** | Jump List | `[j` / `]j` (`[J` / `]J`) | Jump to older/newer position in the Vim jump list |
| **`l`** | Location List | `[l` / `]l` (`[L` / `]L`) | Jump to previous/next location list item |
| **`o`** | Oldfiles | `[o` / `]o` (`[O` / `]O`) | Jump to previous/next recently opened file |
| **`q`** | Quickfix List | `[q` / `]q` (`[Q` / `]Q`) | Jump to previous/next quickfix item |
| **`t`** | Treesitter | `[t` / `]t` (`[T` / `]T`) | Jump to previous/next Treesitter syntax node |
| **`u`** | Undo States | `[u` / `]u` (`[U` / `]U`) | Jump to previous/next state in the undo history |
| **`w`** | Windows | `[w` / `]w` (`[W` / `]W`) | Jump to previous/next window layout |
| **`x`** | Git Conflicts| `[x` / `]x` (`[X` / `]X`) | Jump to previous/next git merge conflict |
| **`y`** | Yank History | `[y` / `]y` (`[Y` / `]Y`) | Jump to previous/next item in yank history |

---

## 🛠️ Common Navigation & Editing Shortcuts

| Key | Action / Command | Description |
| :--- | :--- | :--- |
| **`<C-o>`** | `bprev` | Go to previous open buffer |
| **`<C-p>`** | `bnext` | Go to next open buffer |
| **`<C-S-x>`** | `bdelete` | Delete/close current buffer |
| **`<leader><C-o>`** | `%bd\|e#` | Delete all buffers except the current one |
| **`<leader>o`** | `only` | Close all window splits except the current one |
| **`<leader>c`** | `noh` | Clear search highlight highlighting |
| **`<leader>?`** | `<CMD>lua _G.toggle_cheatsheet()<CR>` | Toggle Cheatsheet |
| **`<C-w>`** | `w!` | Quick force-save current file |
| **`<C-s>`** | `ZZ` | Save and quit Neovim |
| **`<C-x>`** | `ZQ` | Force quit Neovim without saving |

### 🕳️ Smart Cuts & Deletes (Clipboard Protection)

By default, standard `d`/`c` commands overwrite your system clipboard. The following mappings protect your clipboard:

*   **`d` / `D`**: Delete text to the black hole register `_` (does **not** overwrite clipboard).
*   **`cc` / `C`**: Cut text to the default register (acts like standard `dd`/`D`, overwriting clipboard).
*   **`"*d` / `"*D`**: Delete text directly to the system clipboard `*`.
*   **`"*c` / `"*C`**: Cut text directly to the system clipboard `*`.

---

## 💬 Commenting Code (`mini.comment`)

Useful for quickly commenting/uncommenting sections of code or Nix attribute sets.

*   **Syntax**: `gc` + **motion/textobject** (or `gb` for block comment)

| Action / Shortcut | Description | Examples / Use Case |
| :--- | :--- | :--- |
| **`gcc`** | Comment current line | Toggle comment on the current line |
| **`gbc`** | Block comment current line | Toggle block comment (`/* comment */`) on current line |
| **`gc`** (Visual Mode) | Comment selected text | Select multiple lines and press `gc` to toggle comments |
| **`gcip`** | Comment current paragraph | Comments out the block of code/paragraph you are currently in |
| **`gci{`** or **`gci}`** | Comment inside curly braces | Comments out the contents inside a Nix attribute set or brace block |
| **`gca{`** or **`gca}`** | Comment around curly braces | Comments out the curly braces themselves and everything inside |

---

## 🥪 Surrounding Text/Objects (`sandwich`)

Add, delete, or change surrounding quotes, parentheses, brackets, or Nix braces.

| Operation | Action / Keys | Example | Result |
| :--- | :--- | :--- | :--- |
| **Add** Surrounding | `sa` + **textobject** + **char** | `saiw"` (on `word`) | `"word"` (surround inner word with double quotes) |
| | `saiw{` | `saiw{` (on `word`) | `{ word }` (surround inner word with braces & spacing) |
| | `saiw}` | `saiw}` (on `word`) | `{word}` (surround inner word with braces, no spacing) |
| | `saip(` | `saip(` (on paragraph) | `(paragraph)` (surround block with parentheses) |
| **Delete** Surrounding | `sd` + **char** | `sd"` (on `"word"`) | `word` (delete surrounding double quotes) |
| | `sd{` or `sd}` | `sd{` (on `{ word }`) | `word` (delete surrounding curly braces) |
| **Replace** Surrounding | `sr` + **old** + **new** | `sr"{` (on `"word"`) | `{ word }` (replace double quotes with braces) |
| | `sr"(` | `sr"(` (on `"word"`) | `(word)` (replace double quotes with parentheses) |
| | `sr"'` | `sr"'` (on `"word"`) | `'word'` (replace double quotes with single quotes) |

