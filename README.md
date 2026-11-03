# Afterhours / sh0ds·16

An Arch + NVIDIA game-making desktop, built around **Hyprland and a custom Quickshell shell**. Near-black cool charcoal, violet, amber and coral for attention, one font (JetBrains Mono Nerd Font) everywhere, rounded corners and calm eased motion. No blur, no oversized docks.

The desktop follows the [game development plan](https://github.com/sh0ds/guides/blob/main/gamedev/plan.md): PICO-8 → Picotron → Godot → your own C/Lua engine, with art, sound and devlogs alongside. Making small finished games is the point.

## The shell

Written from scratch in `.config/quickshell/afterhours/`, rather than a downloaded shell preset:

- A floating, rounded rail on every monitor: an apps button, numbered workspaces, the focused window's title, a centred clock (click for the month), recording/sharing state, now playing with cava bars, system stats on click, the Pi, network, a keep-awake toggle, sound, the tray, the inbox and session controls.
- Searchable desktop applications, including keyboard selection and Enter to launch.
- A D-Bus notification server with plain-text content, actions, quiet mode, passive toasts and a bounded session inbox. Screen-sharing events suppress toasts.
- Session menu with explicit confirmation for log out/reboot/power off. Suspend waits for a real Hyprlock lock before sleeping. Power actions retain the DJ VM shutdown guard.

Hyprlock remains the lock, SwayOSD handles hardware volume feedback, and Fuzzel remains a small dmenu backend for existing clipboard, calculator, Wi-Fi and docs helpers. Waybar, SwayNC, Wlogout and tmux are gone; the old configs live in git history.

## Install on the Arch desktop

See [setup, dependencies and migration](docs/desktop-rebuild.md). This cloud checkout is a development environment; installing it here does not change your physical desktop.

```sh
# First inspect local changes and the setup document.
bash install-dotfiles.sh --target /tmp/afterhours-preview
# On your Arch desktop, after dependencies are installed:
bash install-dotfiles.sh
```

The installer backs up replaced files under `~/.dotfiles-backup/` and supports repeat installation. It links most configs to this checkout, so edits in `~/.config` usually edit this repository. Qt, btop, nchat and Zed receive writable copies.

Choose your main display in `.config/hypr/hyprland.lua` (currently **DP-4**), retain the NVIDIA environment settings on NVIDIA, then log out and select Hyprland. The keyboard layout is **German**, with Caps Lock as Escape.

## Daily controls

| Key | Action |
| --- | --- |
| `Super + Return` | Terminal |
| `Super + Space` | Quickshell app search |
| `Super + N` | Quickshell inbox and quiet mode |
| `Super + Shift + Escape` | Quickshell session controls |
| `Super + Escape` | Lock |
| `Super + 1…0` | Workspace |
| `Super + Shift + 1…0` | Move window to workspace |
| `Super + arrows / h j k l` | Focus window |
| `Super + Shift + arrows / h j k l` | Move window |
| `Super + V` | Toggle floating |
| `Super + G` | Toggle window group |
| `Super + B / E / O` | Firefox / files / notes |
| `Super + D` | Docs search |
| `Super + F1` | Shortcut reference |
| `Super + C` | Calculator |
| `Super + Shift + V` | Clipboard history |
| `Super + period` | Emoji picker |
| `Super + Shift + R` | Start / stop a region recording |
| `Print` | Region screenshot to clipboard |
| `Ctrl + Print` | Annotated screenshot |
| `Alt + Print` | Captioned devlog screenshot |
| `Alt + Tab` | Window switcher |
| `Super + Shift + B` | Hide / show the rail |
| `Super + Shift + M` | DJ VM |


Workspaces are plain numbers, free for whatever you are doing. Apps are not forcibly moved to a workspace. Existing gaming and DJ VM rules still apply.

```sh
afterhours quiet true      # no toast popups; inbox still collects
afterhours apps            # open/close the app search
afterhours start           # start once; safe if already running
```

PICO-8 and Picotron require your licensed Lexaloffle downloads. They are not redistributed here. PICO-8 carts stay in `~/code/pico8`; Picotron keeps its own drive. Godot games and the future engine each get their own repository when their plan steps arrive. The shell neither creates nor publishes game projects.

## Design and checks

[Desktop and WM comparison](docs/desktop-rebuild.md#desktop-and-window-manager-comparison) explains the choice of Hyprland. [Architecture and validation](docs/desktop-rebuild.md#architecture) describe the shell, testing and runtime limits.

```sh
python3 -m unittest discover -s tests -v
node tests/test_firefox_pip.js
lua tests/test_firefox_pip.lua
bash check-desktop.sh  # on the actual Arch desktop, inside the installed session
```

The old screenshots show the previous Diag desktop; the Afterhours captures show this implementation. The [legacy setup reference](docs/legacy-desktop.md) retains the existing audio, VM, Firefox and helper documentation; its appearance and shell instructions describe the old setup.

MIT. Some app themes originated in Catppuccin ports; their existing notices remain. The new shell and wallpaper are original to this setup.
