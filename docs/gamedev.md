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

**PICO-8:** open `~/code/pico8` in Zed, or just one cart's folder (the first `F5` in it links the settings below into that folder; reopen the folder once after that). Each game is a folder with a `.p8` that holds the art and sound, and `.lua` files for the code. In PICO-8's code editor the cart only has its includes:

```
#include src/main.lua
#include src/player.lua
```

PICO-8 reads those files every time the cart runs, so the loop is: edit in Zed, `F5` (it saves first). `cart-run` finds the `.p8` that includes the file you're in, jumps to PICO-8 and presses `ctrl+r` there. If PICO-8 isn't open, it starts it with that cart. Sprites and sfx you haven't saved yet stay, since only the code is reloaded. When PICO-8 has another cart loaded, `load` the right one once.

**Picotron:** code lives in `~/code/picotron`, and Picotron sees that folder as `/code` (the `picotron` wrapper links it into Picotron's drive the second time you start it). Make the cart in Picotron as usual and replace its `main.lua` with the `pt` snippet:

```lua
cd("/code/mygame")
include("src/main.lua")
```

Now `F5` in Zed jumps to Picotron and presses `ctrl+r`, which runs the cart and reads the files fresh. Before you release, copy `src` into the cart (`cp /code/mygame/src /ram/cart/src` in Picotron's terminal), drop the `cd` line and save, or the cart only works on this machine. `/code` is the real folder: `rm` in there deletes for real.

### What Zed knows

Starting `pico8` / `picotron` writes a `.luarc.json` into `~/code/pico8` / `~/code/picotron`. Commit it. It tells the Lua language server which console it's looking at:

- every API function with its arguments and a short description on hover (PICO-8's come from the pico8-ls project, Picotron's are hand-written in `~/.local/share/fantasy-lua/picotron/picotron.lua`, so add one there if Zed calls a real function undefined)
- whole `.p8` carts: the header, `#include` lines and the `__gfx__` / `__map__` / `__sfx__` data read as comments, so a cart with its code inside opens without errors
- PICO-8's own syntax: `+=`, `!=`, `//` comments, `if (a) b()` and `while (a) b()` on one line, `?"hi"`, `a\b`, `^^`, `@addr`, and the button glyphs, so `btn(❎)` works
- no `string.`, `table.` or `math.` in PICO-8, because the console doesn't have them either
- a warning for every name that isn't defined anywhere, which is how typos show up

The PICO-8 part is a language server plugin, `~/.local/share/fantasy-lua/pico8-plugin.lua`. It changes what the server reads, never your files. The first time Zed opens a cart after it's in place, the server asks whether to trust the plugin: say yes once. `pico8` rewrites `.luarc.json` when the dotfiles change it, so commit that file when git shows it changed.

Keys: `F5` runs the cart, `F7` counts PICO-8 tokens (`p8tokens`, the limit is 8192). The count follows the includes and is within a few tokens of PICO-8's own. Near the limit, trust the number in PICO-8's code editor. Snippets: `p8` (the three callbacks), `pt` (Picotron's dev `main.lua`), `fn`, `lfn`, `fori`, `forall`, `forp`, `forxy`.

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
