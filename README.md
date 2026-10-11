# dotfiles

My Arch + Hyprland setup, themed in Catppuccin Mocha.

![desktop](screenshots/desktop.png)

![demo](screenshots/demo.gif)

## Description

The configs I use on my desktop. It runs Hyprland 0.56 with the new Lua config. `hyprland.lua` is the base config and `rice.lua` has all the theming, animations, window rules and extra keybinds on top of it. If something in `rice.lua` breaks, the base config keeps working.

### Look

Only the focused window gets the blue-to-mauve border and a soft glow, the rest are slightly dimmed. If there's just one window on a workspace it fills the whole screen without gaps. Windows open with a small pop and settle into place, and every pop-up (drop-down terminal, SoundCloud, WhatsApp, music, notes) slides down from the top of the screen. Bars, menus and notifications sit on frosted glass.

### Bar

waybar with three parts:

- **Left:** workspace dots, the current song or video (click to pause, scroll to skip) and live audio bars
- **Middle:** the clock (hover for a calendar), plus a red LIVE pill when I'm sharing my screen and REC when I'm recording
- **Right:** tray, a "stats" pill (hover for CPU load and temperature, RAM, GPU load and disk), and one pill for my Raspberry Pi (green when it's online), volume, network, notifications and a power button

### Everything else

- **swaync** for notifications. `SUPER+N` opens the panel, which slides in from the right.
- **swayosd** shows a little pill when you change the volume or brightness.
- **hyprlock** is the lock screen. It shows the cover and title of whatever is playing.
- **hypridle** locks after 10 minutes, turns the screens off after 11 and suspends after an hour.
- **wlogout** is the power menu (lock, suspend, reboot, shutdown).
- **awww** for wallpapers. `SUPER+W` picks a random one from `~/Pictures/walls`.
- **kitty + tmux** for the terminal. kitty has a cursor trail and sends a notification when a command that took longer than 15 seconds finishes while you're looking elsewhere. The tmux prefix is `Ctrl+A`, `|` and `-` split panes, `h j k l` move between them and `Alt+1-5` jumps to a window.
- **Neovim** with LazyVim. My cheat sheet for it is in [docs/neovim.md](docs/neovim.md).
- **fuzzel** as the launcher. It also runs the calculator, docs search, clipboard history and window switcher.
- **mpd + rmpc** for my own music. mpd plays everything in `~/Music` in the background, rmpc is the player for it with album covers, playlists and search. `SUPER+U` slides it down like the other pop-ups. Thanks to mpd-mpris the bar, the media keys and the lock screen pick it up just like SoundCloud. Press `?` in rmpc for all its keys.
- **udiskie** mounts USB sticks as soon as you plug them in and sends a notification. Click Browse to open a terminal in it. `SUPER+SHIFT+U` unmounts them all, so it's safe to pull them out.
- **Audacity** for recording and editing audio. `SUPER+SHIFT+A` opens it on workspace 4, and while it's open the screen won't lock or suspend, so long recordings don't get cut off.
- **fastfetch** with a custom "sh0ds" logo.
- **bash** with [starship](https://starship.rs) as the prompt, eza instead of ls, fzf on `Ctrl+R` for history and zoxide (`z`) to jump to folders. New terminals greet you with fastfetch.

### Window rules

SoundCloud runs as a web app through [PWAsForFirefox](https://github.com/filips123/PWAsForFirefox) and always opens in the scratchpad, so `SUPER+S` slides it in and out like the drop-down terminal. WhatsApp runs in the terminal with [nchat](https://github.com/d99kris/nchat) and slides down on `SUPER+I`, in its own scratchpad. Steam and all games go on workspace 5. Games get adaptive sync and skip vsync for lower input lag, and the screen never locks while one is fullscreen. Firefox picture-in-picture videos stay small in the bottom right corner on every workspace.

### Scripts

Small scripts in `.local/bin` I wrote for things I kept needing:

- `dropterm`, `quicknote`, `chat` and `music`: drop-down terminal, notes (`~/notes/inbox.md`), WhatsApp and the music player. All four use `scratch`, which starts the window the first time and slides it in and out after that
- `chat-notify`: turns new WhatsApp messages into notifications; click one and WhatsApp slides in
- `winswitch`: ALT+Tab through all windows, most recent first
- `calc`: calculator, try `2^10`, `15% of 89` or `300 EUR to USD`
- `docs`: search docs from anywhere. `h` for Hoogle, `p` for Hackage, `w` for the Arch Wiki, `m` for man pages, anything else goes to DuckDuckGo
- `ocr`: drag a box around any text on screen and it's copied to your clipboard
- `rec-toggle`: record a part of the screen to `~/Videos`
- `share-picker`: a faster screen-share picker, since the default one kept freezing with Discord
- `live-status`: turns on do-not-disturb while I share or record my screen, so nothing private pops up on stream
- `wall-next`, `nightlight`, `waybar-cava`, `gpu-status`, `pi-status`, `rec-status`, `np-title`, `np-art`: wallpapers, warm screen colours, and the small helpers behind the bar and the lock screen

Each script has a short comment at the top explaining what it does.

## Screenshots

SoundCloud in the scratchpad and the notification panel:

![popups](screenshots/popups.png)

The power menu:

![power menu](screenshots/power.png)

The lock screen, with the cover and title of whatever is playing:

![lock screen](screenshots/lock.png)

## Getting Started

### Dependencies

Arch with Hyprland 0.56 or newer (the Lua config doesn't work on older versions) and these packages:

```
sudo pacman -S --needed hyprland hyprlock hypridle hyprsunset hyprpicker xdg-desktop-portal-hyprland \
  waybar kitty tmux neovim fuzzel swaync swayosd awww cava fastfetch \
  grim slurp satty wl-clipboard cliphist wf-recorder playerctl brightnessctl jq socat \
  libqalculate tesseract tesseract-data-eng libnotify hyprpolkitagent pavucontrol firefox \
  audacity pipewire-alsa mpd rmpc mpd-mpris udiskie starship eza fzf zoxide ttf-jetbrains-mono-nerd
yay -S wlogout catppuccin-cursors-mocha nchat
```

### Installing

Just clone the repo and run the install script. It symlinks everything into your home folder and moves your old files to `~/.dotfiles-backup/` first, so nothing gets lost.

```
git clone https://github.com/sh0ds/dotfiles.git ~/code/dotfiles
bash ~/code/dotfiles/install-dotfiles.sh
```

Then change a few things to fit your setup:

- Replace `/home/sh0ds` with your own home folder in `hypr/xdph.conf`.
- For SoundCloud, install it as an app with PWAsForFirefox and put its launch command in the autostart block of `hyprland.lua` (replace my ID in the `firefoxpwa site launch` line). Put the same ID in the `soundcloud` line in `rice.lua`, that's how it knows which window to slide in.
- For WhatsApp, run `nchat --setup` once, pick WhatsApp and scan the QR code with your phone. For notifications, quit nchat and run:

  ```
  f=~/.config/nchat/ui.conf
  sed -i '/^desktop_notify_\(enabled\|connectivity\|command\)=/d' "$f"
  printf '%s\n' 'desktop_notify_enabled=1' 'desktop_notify_connectivity=0' "desktop_notify_command=chat-notify '%1' '%2'" >> "$f"
  ```
- For music, put your files in `~/Music` and start mpd once. It picks up new files on its own after that:

  ```
  mkdir -p ~/Music ~/.local/share/mpd/playlists
  systemctl --user enable --now mpd.service mpd-mpris.service
  ```
- In Audacity, set the theme to Dark in the preferences (there's no Catppuccin theme for it) and pick `pipewire` or `default` as the recording device. To record what's playing on your PC, like SoundCloud, start a recording, open pavucontrol and set Audacity to "Monitor of" your speakers in the Recording tab.
- The keyboard is set to German with Caps Lock as Escape. Change `kb_layout` in `hyprland.lua` if you use a different layout.
- Not on NVIDIA? Delete the two NVIDIA lines in `hyprland.lua`.
- `pi-status` and `arena-dev` are for my Raspberry Pi, so either delete them or set `PI_HOST` to your own.

### Executing program

Log out and back into Hyprland. To see if anything is missing, run this. It lists every tool with OK or FAIL:

```
bash ~/code/dotfiles/check-desktop.sh
```

### Keybinds

| Key | What it does |
| --- | --- |
| `SUPER+Return` | Terminal |
| `SUPER+Z` | Drop-down terminal |
| `SUPER+O` | Drop-down notes |
| `SUPER+B` | Firefox |
| `SUPER+S` | Show or hide SoundCloud (the scratchpad) |
| `SUPER+I` | Show or hide WhatsApp |
| `SUPER+U` | Show or hide the music player |
| `SUPER+SHIFT+U` | Unmount USB sticks |
| `SUPER+SHIFT+S` | Send a window to the scratchpad |
| `SUPER+Space` | Launcher |
| `ALT+Tab` | Switch windows |
| `SUPER+C` | Calculator |
| `SUPER+D` | Search docs |
| `SUPER+SHIFT+V` | Clipboard history |
| `SUPER+SHIFT+T` | Copy text from the screen |
| `Print` | Screenshot of a region to the clipboard |
| `SHIFT+Print` | Screenshot of the whole screen to `~/Pictures` |
| `CTRL+Print` | Screenshot and draw on it |
| `SUPER+SHIFT+R` | Start or stop recording |
| `SUPER+SHIFT+C` | Colour picker |
| `SUPER+N` | Notifications |
| `SUPER+W` | New wallpaper |
| `SUPER+SHIFT+N` | Night light |
| `SUPER+SHIFT+B` | Hide or show the bar |
| `SUPER+Q` | Close window |
| `SUPER+F` / `SUPER+M` | Fullscreen / maximise |
| `SUPER+V` | Float and center a window |
| `SUPER+T` | Flip the split between two windows |
| `SUPER+X` | Center a floating window |
| `SUPER+G` / `SUPER+Tab` | Group windows into tabs / next tab |
| `SUPER+A` | Open my tmux dev session |
| `SUPER+SHIFT+A` | Audacity |
| `SUPER+Escape` | Lock |
| `SUPER+SHIFT+Escape` | Power menu |
| `SUPER+SHIFT+E` | Log out of Hyprland |

Moving around works with `SUPER` + arrow keys or `h j k l`, add `SHIFT` to move the window and `CTRL` to resize it. `SUPER+1-0` switches workspace, `SUPER+SHIFT+1-0` sends the window there.

## Help

This is set up for my machine (NVIDIA, two 1080p monitors), so some things might need changing on yours. If a keybind for one of the scripts does nothing, run the install script again: new scripts only get linked into `~/.local/bin` when it runs. If WhatsApp notifications don't show up, make sure nchat was closed when you edited `ui.conf`, it overwrites the file when it quits. If the screen-share picker doesn't show up, restart the portal:

```
systemctl --user restart xdg-desktop-portal-hyprland
```

## Credits

Colours by [Catppuccin](https://github.com/catppuccin), the notification theme is from [catppuccin/swaync](https://github.com/catppuccin/swaync) and the Neovim base is [LazyVim](https://github.com/LazyVim/LazyVim).

## License

This project is licensed under the MIT License - see the LICENSE file for details
