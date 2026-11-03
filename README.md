# Afterhours

My Arch + Hyprland desktop for making small games. Near-black charcoal with violet accents, one font (JetBrains Mono Nerd Font), rounded corners and calm motion. The bar, launcher, notifications and power menu are my own Quickshell config, not a preset.

![Afterhours with kitty, fastfetch and cava](screenshots/afterhours-desktop.png)

![The rail with system stats and the month calendar open](screenshots/afterhours-calendar.png)

## Description

- **The rail** is a floating bar on every monitor. It has an apps button, numbered workspaces, the focused window's title, a centred clock (click it for the month), now playing with cava bars, system stats, the Pi, network, a keep-awake toggle, sound, the tray, the inbox and the power menu.
- **Notifications** come from the shell itself: toasts that slide in and out, a quiet mode, and an inbox for the session. Screen sharing hides the toasts.
- **Everything from boot to desktop matches:** the Plymouth splash, the SDDM login, hyprlock and the wallpaper.
- **kitty** has a violet 3 px beam cursor with a short trail, and a two-line starship prompt.
- **Thunar, Firefox, Obsidian, Zed and Helix** use the same palette, with Papirus icons (violet folders) and the Posy cursor.
- Unfocused windows dim a little. Games, video and picture-in-picture never do.
- Wrappers for my game tools: `pico8`, `picotron`, `aseprite`, `bitwig` and `sfx` (jsfxr / ChipTone). PICO-8 and Picotron are paid downloads from Lexaloffle, so they're not in here.
- Plus the DJ VM, a Wi-Fi picker, clipboard history, a calculator, an emoji picker, OCR, screen recording and captioned devlog screenshots.

## Getting Started

You need Arch, Hyprland 0.56 (the Lua config) and Quickshell 0.3.2 or newer. The full package list is in [docs/desktop-rebuild.md](docs/desktop-rebuild.md). Coming from my old Diag setup? Use [docs/install-from-diag.md](docs/install-from-diag.md).

```sh
git clone https://github.com/sh0ds/dotfiles ~/code/dotfiles
cd ~/code/dotfiles
bash install-dotfiles.sh        # links the configs, backs up old ones to ~/.dotfiles-backup
bash system/install-system.sh   # login screen, boot splash, violet folders (needs sudo)
```

Then log out and pick Hyprland. The main monitor is set in `.config/hypr/hyprland.lua` (mine is DP-4). The keyboard is German with Caps Lock as Escape.

Run `bash install-dotfiles.sh` again whenever files get added or removed. It cleans up dead links.

## Keys

- `Super + Return` terminal, `Super + Space` apps, `Super + B` Firefox, `Super + E` files, `Super + O` notes
- `Super + N` inbox, `Super + Shift + Escape` power menu, `Super + Escape` lock
- `Super + 1…0` workspace, `Super + Shift + 1…0` move the window there
- `Super + arrows` or `h j k l` focus, add `Shift` to move the window
- `Super + V` float and centre, `Super + F` fullscreen, `Super + G` group, `Super + Q` close
- `Super + C` calculator, `Super + Shift + V` clipboard, `Super + period` emoji, `Super + D` docs
- `Print` region to clipboard, `Ctrl + Print` draw on it, `Alt + Print` captioned devlog shot
- `Super + Shift + R` record a region, `Super + Shift + B` hide the rail, `Super + Shift + M` DJ VM
- `Super + F1` lists all of them

## Help

```sh
afterhours restart       # restart the shell
afterhours debug         # run it in the foreground and see errors
afterhours quiet true    # no toasts, the inbox still collects
bash check-desktop.sh    # checks the installed session
python3 -m unittest discover -s tests
```

The old Diag setup and its screenshots are in [docs/legacy-desktop.md](docs/legacy-desktop.md).

## License

MIT. A few app themes started as Catppuccin ports and keep their notices. The shell and wallpaper are mine.
