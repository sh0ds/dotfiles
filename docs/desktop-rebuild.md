# Afterhours: the game-making desktop

## Direction

Keep the useful DNA: Lua, a pixel-console identity, numbered workspaces, keyboard access and the Pi/site connection. Replace the old diagnostic dashboard with a game-making workbench. Charcoal has a slight violet cast; violet is reserved for focus. Status dots are violet when fine, amber means attention, coral marks recording and errors. Artwork and games retain their own palette.

The new shell is Quickshell QML. It uses opaque surfaces, 8 px control radii and 14 px panel radii, fine separators, 200 ms colour changes and 320 ms ease-out movement. Windows get 10 px squircle corners, a soft drop shadow and a violet gradient border; Hyprland's springs are tuned to the same pace. There is no wallpaper blur, colour cycling or glow, and the wallpaper's clouds only drift while the workspace is empty. One font everywhere: JetBrains Mono Nerd Font.

`Theme.qml` owns shell tokens. Application themes are explicit native configs in kitty, GTK, Qt, Zed, btop, Firefox, MPV and the existing music/chat tools. Existing `diag` filenames and internal theme identifiers remain stable so integrations and installed app selections continue resolving them. Their colours are Afterhours.

## Desktop and window manager comparison

This is a practical comparison for this user's Arch/NVIDIA, two-monitor, keyboard-driven game development workflow. It is not a benchmark or a claim to have installed every project. NVIDIA behaviour depends on driver, kernel and compositor versions; test the actual machine before treating any combination as guaranteed.

| Option | Strength | Fit for this setup |
| --- | --- | --- |
| **Hyprland** | Dynamic tiling, Lua config here, layer-shell, per-output controls, gaming rules | **Chosen.** P1 explicitly teaches Lua through Hyprland; retains monitor and game rules while the shell is rebuilt independently. |
| niri | Scrolling columns, strong workspace model | Excellent alternative for wide work; different window model and IPC require rewriting this workflow. |
| Sway | Predictable i3-style manual tiling on Wayland | Good restrained alternative; NVIDIA support requires checking its current driver policy. No direct fit for the plan's Lua exercise. |
| River | Composable Wayland workspace/layout approach | Attractive for a small custom system; more integration work and different rules. |
| labwc | Lightweight stacking Wayland compositor | Good conventional windows; tiling would require a different workflow. |
| Wayfire | Plugin-driven Wayland desktop effects | More effect-oriented than the compact game workbench needs. |
| dwl | Small, source-configured Wayland tiler | Strong minimalism; rebuilding C for configuration distracts from the early game tracks. |
| Qtile | Python-configured tiling, Wayland/X11 backends | Good programmable option; replaces the plan's Lua exercise with Python. |
| Miracle-WM | Tiling based on Mir | Interesting integrated direction; existing Hyprland integration would need replacing. |
| KDE Plasma | Complete settings, device integration, strong gaming desktop | Best full-desktop alternative. KWin is not a drop-in layer-shell replacement for this Hyprland-oriented shell. |
| GNOME | Consistent defaults and focused workflow | Full desktop with a different interaction model; extensive tiling customisation relies on extensions. |
| COSMIC | Tiling-oriented full desktop | Worth considering as an integrated alternative; does not reuse this Lua/Hyprland workflow. |
| Xfce | Mature, light, conventional desktop | Solid conservative choice; less aligned with a custom Wayland tiling shell. |
| Cinnamon | Familiar desktop and settings | Good conventional workstation; less suited to building the shell independently. |
| MATE | Traditional and light | More relevant for a classic desktop than this workflow. |
| LXQt / LXDE | Small resource footprint | Useful on low-powered machines; not the main constraint here. |
| Budgie | Conventional panel-based desktop | Good cohesive defaults; custom shell overlaps its role. |
| Pantheon | Curated application/desktop design | Favours its own integrated design rather than a custom tiling environment. |
| Deepin | Visual integration and conventional desktop | Less useful than control over this specific game-making workflow. |
| Enlightenment | Unusual, highly customisable desktop shell | Distinct visual potential; Quickshell would overlap its existing shell. |
| Trinity | Classic desktop continuity | Different priorities from a modern Wayland game workstation. |
| i3 | Clear manual tiling and IPC on X11 | Strong fallback if Wayland blocks a crucial application; needs a separate X11 shell approach. |
| bspwm | Simple tree tiling, scriptable IPC | Excellent X11 tiler, but Quickshell's Wayland panels are the chosen foundation. |
| awesome | Rich Lua-driven X11 desktop | Strong runner-up for Lua, but builds its own shell in Lua and loses the intended Wayland stack. |
| xmonad | Typed, composable layouts in Haskell | Powerful; Haskell is no longer in the game plan's core stack. |
| dwm | Very small C tiler | Appealing for learning C, but maintaining patches is separate work from shipping games. |
| herbstluftwm / spectrwm | Controlled X11 tiling | Useful specialist alternatives; do not improve the chosen Quickshell/Wayland fit. |
| Openbox / Fluxbox / IceWM / cwm / FVWM | Lightweight, flexible X11 stacking | Strong for traditional workflows; tiling and shell integration require a different design. |

Hyprland wins on fit, not because every other desktop is worse. The cost is compositor-specific integration and version-sensitive config. Keep its Lua config understandable for P1, and let Quickshell own presentation. Reconsider Plasma if the user later wants integrated settings over custom shell control; reconsider niri if scrolling columns become the priority.

## Dependencies and migration

The physical machine is Arch with NVIDIA and DP-4 as its current main monitor. The cloud validation machine is Debian with software-rendered, headless Wayland. These are different test targets.

On Arch, update normally and install the shell prerequisites using the signed package repositories:

```sh
sudo pacman -Syu --needed hyprland quickshell qt6-wayland qt6-declarative \
  hyprlock hypridle hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  kitty noto-fonts ttf-jetbrains-mono-nerd cava \
  libqalculate unicode-emoji fuzzel wl-clipboard cliphist jq socat playerctl pavucontrol \
  wireplumber pipewire-pulse libnotify grim slurp satty wf-recorder wtype \
  less zed thunar adw-gtk-theme qt6ct papirus-icon-theme
```

Optional, for violet folders: `yay -S papirus-folders`; `system/install-system.sh` recolours them.

Use **Quickshell 0.3.2+**, and the **Hyprland 0.56 Lua API** used by this checkout. Do not blindly upgrade into an incompatible config format. Check `quickshell --version` and `Hyprland --version` before migrating. Package names are Arch-specific; availability can change with repository packaging.

Keep the existing audio, VM, music and app dependencies from [the legacy reference](legacy-desktop.md) if you use those features. The new shell does not install or configure a virtual machine, NVIDIA drivers, a firewall or a login manager for you.

Before installing:

1. Inspect `git status --short` and preserve local edits. Keep a second TTY available for recovery.
2. Review DP-4, monitor position, German keyboard layout and NVIDIA environment variables in `hyprland.lua`. Keep the GPU settings for this machine; remove them if migrating to a different GPU.
3. Check the isolated install with `bash install-dotfiles.sh --target /tmp/afterhours-preview`.
4. On the physical desktop, run `bash install-dotfiles.sh`. Do not run the system installer just to change the theme.
5. Log out and select Hyprland. Waybar, SwayNC and Wlogout were removed; if an old session still runs them, they must exit. Do not run another notification daemon alongside Afterhours.
6. Run `bash check-desktop.sh`, test both monitors, a game, sound, screen sharing, lock/unlock and suspend/resume. Inspect `hyprctl configerrors`.

The installer backs up overwritten targets. To roll back, exit the new session, restore the affected files from the timestamped backup and use the prior Git revision for the old shell. Configuration links point into the checkout: changing Git revisions also changes linked configs. Saved writable copies (Qt, Zed, btop, nchat) need reinstalling or restoring too. No automatic live rollback or remote logout is attempted.

## Game plan tools

Install tools when their track needs them, so P1 does not become a month of toolchain setup.

| Stage | Tools | Notes |
| --- | --- | --- |
| P1 | Lua, Lua language server, this config | Change one rule yourself; the shell does not claim this learning step is completed. |
| P2–P8 | Licensed PICO-8 | Unzip to `~/.local/opt/pico-8`; wrapper keeps carts in `~/code/pico8` and GIFs/screenshots in `~/Pictures/pico-8`. |
| T1–T4 | Licensed Picotron | Unzip to `~/.local/opt/picotron`; retain its own drive. |
| A1–A2 | Pixelorama or Aseprite | `pixelorama`, or `aseprite` (installed with Steam, started as the binary). |
| A3–A4 | PICO-8 tracker, your existing DAW, ChipTone | PICO-8 first; `bitwig` for loops; `sfx` opens jsfxr, `sfx chiptone` ChipTone. |
| G1–G11 | `godot` | Use Godot 4, typed GDScript warnings, one repo per game; download version-matched export templates in the editor. |
| X1–X8 | `base-devel clang gdb pkgconf sdl3 lua lua-language-server emscripten` | Check `pkg-config --cflags --libs sdl3 lua`; later check `emcc --version`. Keep engine name for X1, not a fabricated placeholder repository. |
| W / F | C/make, Python, browser devtools, FFmpeg | Website work belongs on the plan's `next` branch. The shell does not switch branches or deploy. |
| J / I | itch.io, butler when needed | Credentials and uploads remain explicit actions. No automatic publishing or scope generation. |

The PICO-8/Picotron wrappers validate the executable when launched. PICO-8's Lua dialect is not standard Lua: do not format or rewrite carts as if it were.

## Architecture

- `shell.qml`: per-output rail, one focused-output overlay, native desktop-entry launcher, MPRIS, SNI tray, notifications and IPC. No HTTP service or internet requests.
- `Theme.qml`: shell palette and typography.
- `Cell.qml`: shared keyboard-focusable control with hover and focus states.
- `Hint.qml`: hover hints for rail controls in their own popup window, because the rail window is too short for a QtQuick `ToolTip`.
- `Notice.qml`: bounded text presentation, action controls and toast lifetime.
- `Meter.qml`: the slim slider used by the OSD, the media card and the control centre.
- `Osd.qml`: the volume popup on the focused monitor, fed straight from PipeWire. Replaces SwayOSD.
- `ScreenFrame.qml`: the thin screen-edge frame that joins the rail. Click-through. Not `Frame`: that name belongs to QtQuick.Controls, which shell.qml imports, so it would win.
- `Wallpaper.qml`: the haze picture plus drifting clouds on the background layer. Replaces awww; it stops rendering while the workspace has a window or game mode is on.
- `MediaCard.qml`: the popup under now playing (cover, seek, shuffle, loop, cava).
- `ControlCenter.qml`: the popup under `vol` and the network icon (outputs, mic, app volumes, Wi-Fi via `nmcli`, toggles).
- `Lock.qml`: the session lock (`ext-session-lock`) with PAM through `pam/password.conf`. Sets logind's locked hint.
- `Overview.qml`: every workspace with live window previews (screencopy), drag to move, middle-click to close.
- `afterhours`: starts once or sends typed Quickshell IPC calls; no process-name-wide kills.
- `afterhours-suspend`: locks through the shell (Hyprlock if the shell can't), waits for logind's locked hint, then suspends.

If the shell dies while the screen is locked, the screen stays locked (that is the protocol). Switch to a TTY with `Ctrl + Alt + F3`, log in and run `hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'`, then switch back to the desktop TTY (`Ctrl + Alt + F1` or `F2`) and unlock with hyprlock. `misc.allow_session_lock_restore` in `rice.lua` allows that hand-over.

Game mode turns itself on while the focused workspace has a fullscreen game (a `steam_app_*` or gamescope window, anything Hyprland tags as game content, or fullscreen on workspace 5). It switches animations, dimming and shadows off with `hyprctl eval` and hides the rail and frame. Single windows still cover the frame because of the smart gaps.

The inbox is session-only, capped at 50 notifications; it is not written to disk. Quiet mode hides toasts, not inbox entries. Critical toasts stay visible until dismissed. Transient notifications expire; ordinary ones leave the toast after a short interval and remain in the inbox. The shell renders notification content as plain text, never HTML. Sharing suppression uses Hyprland `screencastv2` events; a shell started in the middle of an existing share cannot infer an earlier start event. Enable quiet mode before presenting in that case.

The layer-shell names are `afterhours-rail`, `afterhours-overlay`, `afterhours-toast`, `afterhours-osd`, `afterhours-frame`, `afterhours-wallpaper` and `afterhours-overview`. Screens are enumerated dynamically. Workspace focus uses the same Lua dispatcher syntax as the compositor config. A focused monitor is selected by name for keyboard-opened panels. Workspaces show as numbers in a rounded track: the active one is a violet pill, numbers with windows are bright, empty ones dim. Narrow rails shorten the clock and hide optional media/tray content; DP-4 always shows workspaces 1–5, every rail also lists its own open workspaces, and the mouse wheel steps through them. All ten workspaces remain keyboard-accessible.

Utilities such as clipboard search, docs and the Wi-Fi password prompt still use their existing Fuzzel dmenu helpers. Maths, emoji and the window switcher are launcher modes now. Old app and VM scripts remain maintained independently. There is no fake progress counter, permanent timer pressure, app-per-workspace cage or telemetry.

## Validation

The development report records actual results from this change. Required checks include Python helper regressions, JavaScript and Lua PiP regressions, a repeatable isolated install, shell startup, opening panels through IPC, application search, notification delivery/dismissal and rendering at multiple output sizes. Headless rendering demonstrates the real QML, not a browser mockup.

Headless software Wayland does not prove physical NVIDIA operation, real Hyprland dispatch, real audio hardware, licensed-console operation, lock/unlock or suspend. Run those final hardware checks in the Arch session. The cloud machine must not be made to suspend, reboot or log out as a test.

### Results from the cloud instance

- Built Quickshell 0.3.2 from upstream commit `9b0f339b19057f4731bf3b48293307d7ef241671` against Qt 6.8.2. Required newer protocol definitions came from the upstream Wayland protocols mirror at `b9edf66597586c914b5b1ff3d964d7ed201adab9`. Dependencies were downloaded through the session proxy with Debian signature verification intact and extracted into a workspace-local sysroot. No verification was disabled.
- Cold-started the actual QML under isolated, software-rendered Wayland and D-Bus. Ran functional checks for keyboard dismissal, real desktop-entry search/launch with a literal argument containing spaces and `&`, rail toggling, notifications, quiet mode, inbox removal and session-menu cancellation.
- Rendered at 1600×1000, 800×600 and 600×900. The committed Afterhours screenshots are actual Wayland captures. The small menu scrolls; the portrait menu drops the optional key artwork column.
- **38 Python tests passed**, including eight new shell/helper regressions. Existing JavaScript add-on and Lua PiP suites passed. Hyprland Lua syntax and TOML files parsed successfully.
- The actual checkout installed into an isolated home, preserved a pre-existing config, included every new shell asset and repeated without creating an extra backup.
- Both C site generators built with their default ASan/UBSan flags. Each generated three posts; checked indexes, ordering, static copies and seven HTTP routes. Their existing path-truncation compiler warning is unchanged.

The final cold-started shell produced no QML runtime errors during its smoke run. Its expected warning is that Hyprland IPC is unavailable under the cloud's Sway test compositor. Real Hyprland/NVIDIA dispatch, proprietary console binaries, sound hardware and locking/suspend are not validated by this headless session. The prepared compiler/runtime files under `/workspace/desktop-rebuild` are cloud snapshot dependencies, not new user project repositories.
