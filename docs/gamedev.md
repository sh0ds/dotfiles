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

## Godot

`godot` from pacman is the current Godot 4. Two things to set once in the editor:

1. **Export templates:** Editor → Manage Export Templates → Download and Install. Without them there's no web, Linux or Windows build.
2. **Zed as the script editor:** Editor → Editor Settings → Text Editor → External. Turn on Use External Editor, Exec Path `zeditor`, Exec Flags `{project} {file}:{line}:{col}`. Double-clicking a script now opens it in your Godot project's Zed window. The `gdscript` extension installs itself in Zed and gets completion from Godot's language server, so leave the Godot editor open while you write.

Pressing `F5` runs the game in its own window, which floats centred over the editor (`rice.lua`, rule `godot-run`).

## Your own engine

`sdl3`, `lua` and `pkgconf` are the desktop build: `pkg-config --cflags --libs sdl3 lua` gives the flags. `emscripten` is the web build: `emcc --version` in a new terminal checks it's on your PATH (`.bashrc` adds `/usr/lib/emscripten`). `gdb` and the `cgcc` alias (ASan and UBSan) are for the crashes.

Zed already has clangd for C and the Lua extension for the carts.

## Aseprite (Steam)

Install it in Steam like a game. Then `aseprite` (or the launcher entry) opens it through Steam and jumps to it if it's already open. It's a native Linux build, so it tiles where you start it instead of going to workspace 5 like the Proton games.

With arguments, `aseprite` runs the binary directly instead, which is the batch CLI, so build scripts can turn `.aseprite` files into sprite sheets:

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
