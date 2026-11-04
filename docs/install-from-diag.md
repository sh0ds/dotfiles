# Install Afterhours from the existing Diag desktop

This guide assumes your current Arch/NVIDIA desktop uses the old checkout at `~/code/dotfiles`, with DP-4 as the main monitor and a German keyboard. Substitute your real old checkout path if different. The new desktop has been tested under headless Wayland; your physical NVIDIA, monitors, sound and locking still need checking.

The Afterhours changes have not been pushed to GitHub. Use the provided `afterhours-install.tar.gz` and its SHA-256 file. Publishing the cloud environment does not push these source changes to GitHub.

## 1. Leave your existing checkout in place

Do not overwrite, move or pull changes into `~/code/dotfiles` for this installation. Existing configs are symlinks into it; preserving its absolute path preserves both your current desktop and a working rollback source. The new checkout will live at `~/code/dotfiles-afterhours` permanently while installed.

Check the old checkout and note any local changes:

```sh
git -C "$HOME/code/dotfiles" status --short
readlink -f "$HOME/.config/hypr/rice.lua"
```

## 2. Install the added runtime and fonts

In your current desktop terminal, run a normal full Arch update with the new dependencies:

```sh
sudo pacman -Syu --needed \
  quickshell qt6-wayland qt6-declarative \
  noto-fonts ttf-jetbrains-mono-nerd cava papirus-icon-theme
```

This is the package delta from the existing Diag setup. Keep the existing Hyprland, Hyprlock, Hypridle, portals, Kitty, audio and other helper dependencies. Keep Fuzzel: the clipboard, docs and Wi-Fi password helpers still use it. SwayOSD and awww are no longer used (the shell draws the volume popup and the wallpaper) and can be uninstalled too. Waybar, SwayNC, Wlogout and tmux are no longer used and can be uninstalled.

```sh
quickshell --version
Hyprland --version
```

Quickshell must be **0.3.2 or newer**. The configs target the **Hyprland 0.56 Lua API**, as your existing checkout does; an older `hyprland.conf`-only version cannot run them. A newer compositor release must still support that API. Resolve incompatible versions before switching configuration.

If the update changed the kernel or NVIDIA driver, reboot and verify your current desktop first. This separates package-update problems from the configuration migration.

## 3. Download, verify and unpack the new checkout

Save `afterhours-install.tar.gz` and `afterhours-install.tar.gz.sha256` from the chat into `~/Downloads`. Do not download a normal GitHub ZIP: it does not contain the new changes or the Git index required by this installer.

```sh
mkdir -p "$HOME/code"
cd "$HOME/Downloads"
sha256sum -c afterhours-install.tar.gz.sha256 &&
  test ! -e "$HOME/code/dotfiles-afterhours" &&
  tar -xzf afterhours-install.tar.gz -C "$HOME/code" --no-same-owner
```

The checksum must say **OK**. If the target directory already exists, stop and use a different unused permanent checkout path; do not extract over it.

```sh
git -C "$HOME/code/dotfiles-afterhours" status --short
git -C "$HOME/code/dotfiles-afterhours" branch --show-current
```

Status should be empty; the branch should be `afterhours-install`. The archive includes an independent Git checkout, the complete new source, and a local snapshot commit. Nothing has been pushed remotely.

## 4. Check hardware settings and preview the install

Inspect these files in the **new** checkout:

- `.config/hypr/hyprland.lua`: `main_screen = "DP-4"`, the second monitor to its left, `kb_layout = "de"`, Caps Lock as Escape, and the NVIDIA environment settings.
- `.config/hypr/xdph.conf`: the existing `/home/sh0ds/.local/bin/share-picker` path. Change it if your username/home differs.

Keep settings that already match your machine. Edit the new checkout, not the still-active old one.

Run an isolated installation:

```sh
preview_home=$(mktemp -d /tmp/afterhours-preview.XXXXXX)
bash "$HOME/code/dotfiles-afterhours/install-dotfiles.sh" --target "$preview_home"
test -f "$preview_home/.config/quickshell/afterhours/shell.qml"
test -f "$preview_home/.local/share/backgrounds/afterhours-haze.jpg"
```

This writes into the temporary directory, not your live home. Stop if the installer or either file check fails. Keep the new checkout in its permanent location after the real installation: most installed files will link to it.

## 5. Leave the graphical session

Save your work. If the DJ VM is running, shut Windows down cleanly (`djvm off` uses the existing helper). Close btop, nchat and Zed because they can rewrite the writable configs being replaced.

Log out through your current session menu. Then press **Ctrl+Alt+F3** and log in at the text console. Use TTY3, not TTY1: your `.bash_profile` automatically starts Hyprland on TTY1.

## 6. Install as your normal user

From TTY3:

```sh
bash "$HOME/code/dotfiles-afterhours/install-dotfiles.sh"
```

**Do not use sudo.** The installer must target your home directory. It backs up replaced files and symlinks under `~/.dotfiles-backup/`; leave those backups and the old checkout intact. Because the old checkout stays at its original path, backed-up symlinks still resolve to the old content.

If `~/.config/hypr/hyprland.conf` exists, preserve it before trying the Lua session. From this logged-out console:

```sh
if [ -e "$HOME/.config/hypr/hyprland.conf" ] || [ -L "$HOME/.config/hypr/hyprland.conf" ]; then
  migration_backup=$(mktemp -d "$HOME/.dotfiles-backup/hyprland-conf.XXXXXX")
  mv "$HOME/.config/hypr/hyprland.conf" "$migration_backup/hyprland.conf"
  printf 'Saved legacy config: %s\n' "$migration_backup/hyprland.conf"
fi
```

Do not run `system/install-system.sh` for this migration. Do not replace NVIDIA drivers, your login manager or firewall configuration just to change the desktop shell.

## 7. Start your normal Hyprland session

Return to your normal display manager and choose Hyprland. If you normally start from TTY1 instead, return to that console and log in normally. A fresh session is required: editing/reloading the config does not rerun the startup hook.

The session should start Quickshell, Hypridle, the existing polkit agent and the clipboard watcher. The old shell should not start from this config.

If an independently enabled Waybar/SwayNC service or autostart entry still launches it, identify and disable that specific entry. Do not run SwayNC or another notification daemon alongside Afterhours.

## 8. Check the working desktop

Open a terminal with **Super+Return**:

```sh
export PATH="$HOME/.local/bin:$PATH"
hyprctl configerrors
afterhours status
notify-send "Afterhours" "Notification test"
```

`hyprctl configerrors` should show no configuration errors. `afterhours status` should return JSON. Test these controls:

| Key | Expected result |
| --- | --- |
| Super+Space | Application search; type a name and press Enter |
| Super+N | Inbox containing the notification test |
| Super+1…0 | Workspace changes |
| Super+Shift+Escape | Session controls; Escape cancels |
| Super+Escape | Real lock; verify password unlock works |

Check both monitors, audio, a fullscreen game and screen sharing. Verify lock/unlock before trying suspend. Do not interpret a missing PICO-8, Picotron or Godot installation as a shell failure.

If the shell is absent, run this in a terminal to see startup errors:

```sh
afterhours start
```

For the wider pre-existing desktop inventory:

```sh
bash "$HOME/code/dotfiles-afterhours/check-desktop.sh"
```

This includes old optional app/VM checks; a missing optional tool is distinct from a failed Quickshell/Hyprland check.

## 9. Add game tools when their plan step needs them

- PICO-8: your licensed Linux download goes in `~/.local/opt/pico-8`; run `pico8`. Existing carts stay in `~/code/pico8`.
- Picotron: your licensed download goes in `~/.local/opt/picotron`; run `picotron`.
- Art: Pixelorama or `aseprite` (Steam).
- Sound: the PICO-8 tracker first, `bitwig` for loops, `sfx` opens jsfxr (`sfx chiptone` for ChipTone).
- Godot: install `godot` when reaching G1. Install version-matched export templates in Godot when needed.
- C/SDL3/Emscripten: follow the X-track setup when you reach it; the desktop shell does not require that toolchain.

## Roll back

Save work, log out and return to **TTY3**. Run the installer from the untouched old checkout:

```sh
bash "$HOME/code/dotfiles/install-dotfiles.sh"
```

Then log into your normal Hyprland session again. This restores the old config links and recopies its writable configs. For exact pre-install Zed/btop/nchat/Qt preferences, restore the relevant files from the backup created by the Afterhours installation. If you preserved an older `hyprland.conf`, restore it only if the old setup actually requires it.

New unused Quickshell helpers/configs may remain, but the old Hyprland configuration will not start them. Keep `~/code/dotfiles-afterhours` until you have confirmed the old desktop works; there is no need to uninstall packages or delete either checkout to roll back.
