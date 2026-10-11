# Neovim cheat sheet (LazyVim)

`Space` is the leader: press it and wait for a menu of everything that follows. `Esc` always gets you back to normal mode.

## Modes

| Key                                                 | Mode                               |
| --------------------------------------------------- | ---------------------------------- |
| `Esc` (or Caps Lock, which is Escape in your setup) | Normal: move and run commands      |
| `i` / `a`                                           | Insert before / after the cursor   |
| `I` / `A`                                           | Insert at start / end of line      |
| `o` / `O`                                           | New line below / above, insert     |
| `v` / `V` / `Ctrl+v`                                | Visual: characters / lines / block |
| `:`                                                 | Command line                       |

## Moving

| Key | Moves |
|-----|-------|
| `h j k l` | Left, down, up, right |
| `w` / `b` / `e` | Next word / back a word / end of word |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `gg` / `G` / `42G` | First line / last line / line 42 |
| `Ctrl+d` / `Ctrl+u` | Half page down / up |
| `{` / `}` | Previous / next blank line (paragraph) |
| `%` | Matching bracket `( ) [ ] { }` |
| `f x` / `t x` | Jump onto / before the next `x` on the line; `;` repeats |
| `s` + 2 letters | Jump anywhere on screen (flash) |
| `Ctrl+o` / `Ctrl+i` | Back / forward through jump history |

## Editing

| Key | Does |
|-----|------|
| `x` | Delete character |
| `dd` / `yy` / `cc` | Delete / copy / change whole line |
| `dw` / `cw` | Delete / change to end of word |
| `D` / `C` | Delete / change to end of line |
| `p` / `P` | Paste after / before |
| `u` / `Ctrl+r` | Undo / redo |
| `.` | Repeat last change (the most useful key in vim) |
| `>>` / `<<` | Indent / unindent line |
| `J` | Join line below onto this one |
| `~` | Toggle case |
| `r x` | Replace character with `x` |
| `gcc` / `gc` + motion | Toggle comment on line / range |

## Text objects: verb + `i`(nside) / `a`(round) + object

These are what make vim fast. Combine a verb (`d` delete, `c` change, `y` copy, `v` select) with an object:

| Keys | Acts on |
|------|---------|
| `ciw` | Change the word under the cursor |
| `ci"` / `ci'` | Change inside quotes |
| `ci(` / `ca(` | Inside / including parentheses |
| `di{` | Delete a function body |
| `yap` | Copy a paragraph |
| `vit` | Select inside an HTML tag |
| `cif` / `daf` | Change inside / delete whole function (treesitter) |

## Whole file

| Keys | Does |
|------|------|
| `ggVG` | Select everything |
| `:%y` | Copy whole file (goes to system clipboard) |
| `ggVGp` | Replace whole file with clipboard |
| `ggdG` | Delete everything |
| `gg=G` | Re-indent whole file |

## Search and replace

| Keys | Does |
|------|------|
| `/word` then `Enter` | Search forward; `n` / `N` next / previous |
| `*` | Search word under cursor |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Same, confirm each |
| `Space s r` | Search and replace across the project (grug-far) |
| `Esc` | Clear highlights |

## Files and buffers (LazyVim)

| Keys | Does |
|------|------|
| `Space Space` | Find file in project |
| `Space /` | Grep text in project |
| `Space f r` | Recent files |
| `Space e` | File tree (`a` add, `d` delete, `r` rename, `q` close) |
| `Space ,` | Switch open file |
| `Shift+h` / `Shift+l` | Previous / next open file |
| `Space b d` | Close current file |
| `:w` / `Space w` | Save |
| `Space q q` | Quit everything |

## Windows (splits)

| Keys | Does |
|------|------|
| `Space \|` / `Space -` | Split right / below |
| `Ctrl+h/j/k/l` | Move between splits |
| `Space w d` | Close split |
| `Ctrl+Up/Down/Left/Right` | Resize split |

## Code (LSP)

| Keys | Does |
|------|------|
| `K` | Hover: type and docs |
| `gd` / `gr` | Go to definition / references |
| `gI` | Go to implementation |
| `Space c a` | Code action (quick fix) |
| `Space c r` | Rename symbol everywhere |
| `Space c f` | Format file |
| `]d` / `[d` | Next / previous diagnostic |
| `Space c d` | Show error under cursor |
| `Space x x` | All diagnostics in a list |
| `Ctrl+Space` | Trigger completion; `Enter` accepts, `Ctrl+n` / `Ctrl+p` move |

## Git

| Keys | Does |
|------|------|
| `Space g g` | Lazygit (`Space` stage, `c` commit, `P` push, `p` pull, `q` quit) |
| `]h` / `[h` | Next / previous changed hunk |
| `Space g h p` | Preview hunk |
| `Space g h r` | Reset hunk |

## Terminal and tools

| Keys | Does |
|------|------|
| `Space f t` | Floating terminal (close it with `exit`) |
| `:!make` / `Space m a` | Run make |
| `Space l` | Plugin manager |
| `Space s k` | Search all keymaps |
| `Space s h` | Search help |

## Macros (repeat anything)

| Keys | Does |
|------|------|
| `q a` | Start recording into register `a` |
| `q` | Stop |
| `@a` | Play once |
| `10@a` | Play ten times |
| `@@` | Repeat last macro |

Example: turning 20 lines of `x,y` into `[x,y],` for a test file: `qa` → `I[` → `Esc` → `A],` → `Esc` → `j` → `q`, then `19@a`.

## Haskell (local leader is `\`)

| Keys | Does |
|------|------|
| `\r` / `\R` | GHCi REPL for package / this file |
| `\h` | Hoogle the signature under cursor |
| `\e` | Evaluate all `-- >>>` comments |

## When stuck

- `Esc Esc`, then `:q!` quits without saving.
- `u` undoes until you're back to a known state.
- `:checkhealth` explains broken plugins or servers.
- Practice: `nvim --clean +Tutor`.
