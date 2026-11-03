# Helix cheat sheet

Helix selects first, then acts: `w` selects a word, `d` deletes the selection. Vim's `dw` is `wd` here. `Space` opens a menu of everything behind it, `Esc` (or Caps Lock) always gets you back to normal mode. `:tutor` walks through all of this in about 30 minutes.

## Modes

| Key | Mode |
|-----|------|
| `Esc` | Normal: move, select, run commands |
| `i` / `a` | Insert before / after the selection |
| `I` / `A` | Insert at start / end of line |
| `o` / `O` | New line below / above, insert |
| `v` | Select mode: moves extend the selection |
| `:` | Command line |

## Moving and selecting

| Key | Does |
|-----|------|
| `h j k l` | Left, down, up, right |
| `w` / `b` / `e` | Select next word / back a word / to end of word |
| `x` | Select the line, again for the next one |
| `gh` / `gl` / `gs` | Line start / line end / first non-blank |
| `gg` / `ge` / `42gg` | First line / last line / line 42 |
| `Ctrl+d` / `Ctrl+u` | Half page down / up |
| `mm` | Matching bracket |
| `mi(` / `ma"` | Select inside `( )` / around `" "` (any pair works) |
| `f x` / `t x` | Select onto / before the next `x` on the line |
| `gw` | Jump anywhere on screen by label |
| `;` | Collapse the selection to the cursor |
| `Ctrl+o` / `Ctrl+i` | Back / forward through jump history |

## Editing

| Key | Does |
|-----|------|
| `d` / `c` / `y` | Delete / change / copy the selection |
| `xd` | Delete the line |
| `p` / `P` | Paste after / before |
| `u` / `U` | Undo / redo |
| `.` | Repeat the last insert |
| `>` / `<` | Indent / unindent |
| `Ctrl+c` | Toggle comment |
| `C` | Add a cursor on the next line (multi-cursor); `,` back to one |
| `s` | Select a regex inside the selection (multi-cursor on every match) |
| `%` | Select the whole file |

## Search

| Key | Does |
|-----|------|
| `/` / `?` | Search forward / back; `n` / `N` next / previous |
| `*` | Search for the selection |
| `Space /` | Search the whole project (ripgrep-style) |

## Files and buffers

| Key | Does |
|-----|------|
| `Space f` | Find a file in the project |
| `Space b` | Open buffers |
| `gn` / `gp` | Next / previous buffer |
| `Space w` | Window menu: `v` split right, `s` split below, `q` close |
| `:w` / `:q` / `:wq` / `:q!` | Save / quit / both / quit without saving |
| `Ctrl+g` | lazygit, back here when you quit it |

## Code (language servers)

| Key | Does |
|-----|------|
| `gd` / `gr` | Go to definition / references |
| `Space k` | Type and docs for the thing under the cursor |
| `Space a` | Code actions (fixes, imports) |
| `Space r` | Rename everywhere |
| `Space d` | Diagnostics in this file |
| `]d` / `[d` | Next / previous diagnostic |
| `:format` | Format the file |

`helix --health haskell` (or `c`, `erlang`, `bash`) shows whether the server for a language is found.
