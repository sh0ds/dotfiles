# Game dev

Everything the game plan needs, in the order the tracks use it. `bash check-desktop.sh` has a "Game dev" section that shows what's still missing.

## Packages

```
sudo pacman -S --needed godot sdl3 lua emscripten gdb pkgconf pipewire-jack realtime-privileges kdenlive
yay -S bitwig-studio
sudo usermod -aG realtime "$USER"
```

`pipewire-jack` replaces `jack2` if pacman asks; say yes. Log out and back in once afterwards, for the `realtime` group and for `emcc` on your PATH.

## PICO-8 and Picotron

Paid downloads from lexaloffle.com, unzipped into `~/.local/opt` (see the README). `pico8` and `picotron` start them from the launcher. PICO-8's carts live in `~/code/pico8`, its screenshots and GIFs (`F6`, `F9`) in `~/Pictures/pico-8`.

### Code in Zed, everything else in the console

Write the code in Zed and draw, map and compose in the consoles. PICO-8's code editor fits on a 128x128 screen and has no search across files, no go-to-definition and no git. Its sprite, map, sfx and music editors are the best tools for those jobs, so they stay.

Three keys in Zed do the switching:

- `ctrl+alt+n` makes a new cart and opens it in Zed and in the console. It asks for a name and puts the cart next to the file you're in (`quick-exercises/e8-bounce.p8`), or, from the top of `~/code/pico8`, in a folder of its own (`dash/dash.p8`).
- `F5` saves everything and runs the cart in the console with the code as Zed has it.
- `F7` counts PICO-8 tokens.

**PICO-8:** open `~/code/pico8` in Zed (or one cart's folder: the first `F5` links the settings below into it, reopen the folder once after that). A cart is one `.p8` file with its code inside, so Zed and PICO-8 both write to it: Zed the code, PICO-8 the sprites, map and sound. Two things keep them from undoing each other:

- `F5` jumps to the PICO-8 that has this cart, presses `ctrl+s` there so your art is saved, puts Zed's code back into the file and presses `ctrl+r`. Unsaved sprites never block the reload and never get lost. A PICO-8 that has a different cart open stays as it is, and this cart opens in a second PICO-8 next to it. Close the old one when you're done there.
- `p8guard` runs while PICO-8 does. When you press `ctrl+s` in PICO-8 and it writes back code older than what Zed saved, it puts Zed's code back and keeps the new art. Code you write in PICO-8's own editor is new, so it stays.

So write code in Zed, and use PICO-8's code editor only for a quick look. Whenever the code in the file gets replaced, the version PICO-8 saved lands in `~/.cache/pico8/overwritten/` first.

Bigger games can still split the code into `.lua` files with `#include src/main.lua` in the cart. `F5` and `F7` follow the includes.

**Picotron:** code lives in `~/code/picotron`, and Picotron sees that folder as `/code` (the `picotron` wrapper links it into Picotron's drive the second time you start it). `ctrl+alt+n` in there makes `NAME/main.lua`, opens it in Zed, starts Picotron and copies two lines to the clipboard. In Picotron, paste them over the code in the cart's `main.lua` and save the cart with `save /code/NAME/NAME.p64`:

```lua
cd("/code/NAME")
include("main.lua")
```

The cart now runs the code Zed edits, so Zed and Picotron never write to the same file. `F5` jumps to Picotron and presses `ctrl+r`, which reads the code fresh. It reruns whatever cart Picotron has loaded, so `load /code/NAME/NAME.p64` first when you switch games. Before you release, copy the code into the cart (`cp /code/NAME/main.lua /ram/cart/game.lua` in Picotron's terminal, then `include("game.lua")` without the `cd`), or the cart only works on this machine. `/code` is the real folder: `rm` in there deletes for real.

### The PICO-8 extension for Zed

Zed's Lua colouring trips over a cart's header, so `.p8` files get their own small language: the `__lua__` part is coloured as Lua, the header and the `__gfx__` / `__map__` / `__sfx__` data are greyed out, and the outline panel lists the sections. It lives in `.local/share/zed-pico8` as a dev extension. Set it up once:

```
sudo pacman -S --needed rustup lua-language-server
rustup default stable
zed-pico8
```

Then in Zed: `ctrl+shift+p` > `zed: install dev extension` > `~/.local/share/zed-pico8`. Zed builds it, which takes a minute the first time. When the dotfiles change the grammar later, run `zed-pico8` again and press Rebuild on PICO-8 in the Extensions page (`ctrl+shift+x`).

### What Zed knows

Starting `pico8` / `picotron` writes (and keeps up to date) a `.luarc.json` in `~/code/pico8` / `~/code/picotron`. Commit it. It tells the Lua language server which console it's looking at:

- every API function with its arguments and a short description on hover (PICO-8's come from the pico8-ls project, Picotron's are hand-written in `~/.local/share/fantasy-lua/picotron/picotron.lua`, so add one there if Zed calls a real function undefined)
- whole `.p8` carts: the header, `#include` lines and the `__gfx__` / `__map__` / `__sfx__` data read as comments, so a cart with its code inside opens without errors
- PICO-8's own syntax: `+=`, `!=`, `//` comments, `if (a) b()` and `while (a) b()` on one line, `?"hi"`, `a\b`, `^^`, `@addr`, and the button glyphs, so `btn(❎)` works
- no `string.`, `table.` or `math.` in PICO-8, because the console doesn't have them either
- a warning for every name that isn't defined anywhere, which is how typos show up

The PICO-8 part is a language server plugin, `~/.local/share/fantasy-lua/pico8-plugin.lua`. It changes what the server reads, never your files. The first time Zed opens a cart after it's in place, the server asks whether to trust the plugin: say yes once. Commit `.luarc.json` when git shows it changed.

`F7` (`p8tokens`) counts against the limit of 8192. The count follows the includes and is within a few tokens of PICO-8's own. Near the limit, trust the number in PICO-8's code editor. Snippets: `p8` (the three callbacks), `pt` (Picotron's dev `main.lua`), `fn`, `lfn`, `fori`, `forall`, `forp`, `forxy`.

## Game Boy games (mGBA)

`gba` starts mGBA, which plays Game Boy, Game Boy Color and Game Boy Advance games, including your own builds. Put dumps of your own cartridges in `~/games/roms/gba` and run `roms` (it also runs at login): every game gets a launcher entry under its name without the region tags, so typing "minish" finds The Minish Cap. A game from the launcher starts fullscreen, which turns game mode on; `Ctrl + F` (mGBA's own key) leaves fullscreen. Saves sit next to the game, screenshots go to `~/Pictures/gba`. Each start forces whole-number scaling with no smoothing, so pixels stay sharp, and mGBA pauses when you switch away. Controllers work without setup.

`gba path/to/game.gb` runs any file directly, which is how you test a Game Boy build.

## Godot

`godot` from pacman is the current Godot 4. Two things to set once in the editor:

1. **Export templates:** Editor → Manage Export Templates → Download and Install. Without them there's no web, Linux or Windows build.
2. **Zed as the script editor:** Editor → Editor Settings → Text Editor → External. Turn on Use External Editor, Exec Path `zeditor`, Exec Flags `{project} {file}:{line}:{col}`. Double-clicking a script now opens it in your Godot project's Zed window. The `gdscript` extension installs itself in Zed and gets completion from Godot's language server, so leave the Godot editor open while you write.

Pressing `F5` runs the game in its own window, which floats centred over the editor (`rice.lua`, rule `godot-run`).

## Your own engine

`sdl3`, `lua` and `pkgconf` are the desktop build: `pkg-config --cflags --libs sdl3 lua` gives the flags. `emscripten` is the web build: `emcc --version` in a new terminal checks it's on your PATH (`.bashrc` adds `/usr/lib/emscripten`). `gdb` and the `cgcc` alias (ASan and UBSan) are for the crashes.

Zed already has clangd for C and the Lua extension for the carts.

## Aseprite (Steam)

Install it in Steam like a game. `aseprite` (and the launcher entry) then always starts the binary directly, never through the Steam client, and jumps to it if it's already open. Steam is only needed to install and update it. It's a native Linux build, so it tiles where you start it instead of going to workspace 5 like the Proton games.

With arguments it passes them straight through, so `aseprite file.png` opens a file and the batch CLI lets build scripts turn `.aseprite` files into sprite sheets:

```
aseprite -b hero.aseprite --sheet hero.png --data hero.json
```

## Music: Bitwig Studio

`bitwig` starts Bitwig with PipeWire asking for 128 frames of latency (about 2.7 ms at 48 kHz), low enough to play a MIDI keyboard live. In Bitwig: Settings → Audio, driver **JACK**. PipeWire is the JACK server here, so Bitwig, Firefox and mpd all play at once, nothing gets locked out.

Crackles mean the latency is too low: `PIPEWIRE_LATENCY=256/48000 bitwig`, and if that fixes it, change the default in `~/.local/bin/bitwig`.

Easy Effects sits between everything and the headset, so Bitwig goes through the Virtuoso EQ too. That's what you want when listening, but before you judge a mix, A/B it flat: `easyeffects -b 1` turns the EQ off, `easyeffects -b 2` back on (see [audio.md](audio.md)).

Bitwig only has its own dark theme, so it won't look like Diag.

## Sound effects

`sfx` opens jsfxr in Firefox, `sfx chiptone` opens ChipTone. Both are in the launcher too. Export WAV, then drop them into the game.

## Recording and trailers

`rec-toggle` (`SUPER+SHIFT+R`) records a part of the screen to `~/Videos` with `wf-recorder`. Turning that into a GIF with `ffmpeg` is a step in the portfolio track, so it isn't scripted here. Kdenlive is for cutting the trailer.

## itch.io: butler

butler isn't in pacman. Download it from itch.io and put it in `~/.local/opt/butler` (`.bashrc` puts that folder on your PATH):

```
mkdir -p ~/.local/opt/butler && cd ~/.local/opt/butler
curl -L -o butler.zip https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
unzip butler.zip && rm butler.zip && chmod +x butler
butler login
```

`butler upgrade` updates it later.
