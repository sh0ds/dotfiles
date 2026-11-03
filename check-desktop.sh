#!/usr/bin/env bash
# check-desktop.sh: is everything this rice needs installed and running?
# Changes nothing. Pair it with check-toolchain.sh for the language tools.
# Usage: bash check-desktop.sh          exit code = number of failures
set -u

pass=0
fail=0
check() {
  local name=$1
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'OK    %s\n' "$name"
    pass=$((pass + 1))
  else
    printf 'FAIL  %s\n' "$name"
    fail=$((fail + 1))
  fi
}
section() { printf '\n== %s\n' "$1"; }

# shellcheck disable=SC2317  # called indirectly through check
hypr_version_ok() {
  # Lua config needs Hyprland 0.55 or newer
  local v
  v=$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  [ -n "$v" ] || return 1
  local major minor
  major=${v%%.*}
  minor=${v#*.}
  minor=${minor%%.*}
  [ "$major" -gt 0 ] || [ "$minor" -ge 55 ]
}

section "Hyprland"
check "Hyprland installed" command -v Hyprland
check "Hyprland 0.55+ (Lua config)" hypr_version_ok
check "hyprland.lua in place" test -f "$HOME/.config/hypr/hyprland.lua"
check "no leftover hyprland.conf" test ! -e "$HOME/.config/hypr/hyprland.conf"
for c in hyprlock hypridle hyprctl; do
  check "$c" command -v "$c"
done
check "xdg-desktop-portal-hyprland" test -x /usr/lib/xdg-desktop-portal-hyprland
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  check "Hyprland answers hyprctl" hyprctl version
fi

section "Desktop pieces"
for c in python3 kitty qs awww fuzzel wlogout hyprpicker hyprsunset grim slurp satty wl-copy cliphist wf-recorder playerctl wpctl pavucontrol easyeffects qalc tesseract jq firefox firefoxpwa nchat secret-tool virsh virt-install virt-viewer mpd mpc rmpc mpd-mpris udiskie thunar xarchiver zip unzip xfconf-query aria2c btop wtype checkupdates mpv imv zathura obsidian qt6ct gamemoderun proton-pass xdg-mime yay; do
  check "$c" command -v "$c"
done
check "emoji list (unicode-emoji)" test -r /usr/share/unicode/emoji/emoji-test.txt
check "emoji font" sh -c 'fc-list | grep -qi "Noto Color Emoji"'
check "snapshots (snapper or timeshift)" sh -c 'command -v snapper || command -v timeshift'
check "zathura PDF plugin" test -e /usr/lib/zathura/libpdf-mupdf.so
check "PDFs open in zathura" sh -c 'xdg-mime query default application/pdf | grep -q zathura'
check "adw-gtk3 theme" test -d /usr/share/themes/adw-gtk3-dark
check "Thunar folder handler" sh -c 'test "$(xdg-mime query default inode/directory)" = thunar.desktop'
# tumbler names its D-Bus file org.xfce.Tumbler.Thumbnailer1.service; accept
# any thumbnailer that registers the Thumbnailer1 interface.
check "thumbnail service" sh -c 'ls /usr/share/dbus-1/services/*Thumbnailer1.service >/dev/null 2>&1'
check "GTK portal" test -x /usr/lib/xdg-desktop-portal-gtk
check "paccache timer" systemctl is-enabled paccache.timer
check "fstrim timer" systemctl is-enabled fstrim.timer
check "reflector timer" systemctl is-enabled reflector.timer
check "firewall on (ufw)" sh -c 'systemctl is-active ufw && systemctl is-enabled ufw'
check "KVM (DJ VM)" test -w /dev/kvm
check "virtiofsd (DJ VM shared folder)" test -x /usr/lib/virtiofsd
check "Music/DJ shared folder" test -d "$HOME/Music/DJ"
check "in the gamemode group" sh -c 'id -nG | grep -qw gamemode'
check "Posy cursor in /usr/share/icons" test -f /usr/share/icons/Posy_Cursor_Black/index.theme
check "Terminess Nerd Font" sh -c 'fc-list | grep -qi "Terminess Nerd"'
check "Terminess Nerd Font" sh -c 'fc-list | grep -qi "Terminess Nerd Font"'
check "polkit agent unit" systemctl --user cat hyprpolkitagent.service
check "aria2 running for Firefox (aria2-rpc)" pgrep -f "aria2c --enable-rpc"
check "pipewire running" systemctl --user is-active pipewire
check "NetworkManager running" systemctl is-active NetworkManager

section "Terminal workflow"
for c in tmux starship eza fzf zoxide fastfetch sl lazygit bat tldr; do
  check "$c" command -v "$c"
done
check "tmux config parses" tmux -L check -f "$HOME/.config/tmux/tmux.conf" start-server \; kill-server
check "helix" command -v helix
check "zed (zeditor)" command -v zeditor
check "Zed uses Diag" grep -q '"dark": "Diag"' "$HOME/.config/zed/settings.json"
check "eza has a Diag theme" test -r "${XDG_CONFIG_HOME:-$HOME/.config}/eza/theme.yml"
check "scripts in ~/.local/bin on PATH" command -v app
check "responsive power menu on PATH" command -v power-menu
check "btop uses Diag" grep -q '^color_theme = "diag"' "$HOME/.config/btop/btop.conf"
check "Qt palette path expanded" sh -c 'test -f "$HOME/.config/qt6ct/qt6ct.conf" && ! grep -q @CONFIG_HOME@ "$HOME/.config/qt6ct/qt6ct.conf"'

section "Game dev (docs/gamedev.md)"
check "pico8 unzipped in ~/.local/opt" test -x "$HOME/.local/opt/pico-8/pico8"
check "picotron unzipped in ~/.local/opt" test -x "$HOME/.local/opt/picotron/picotron"
check "godot" command -v godot
check "sdl3 and lua for the engine" pkg-config --exists sdl3 lua
check "emcc on PATH" command -v emcc
check "butler on PATH" command -v butler
check "aseprite in Steam" test -x "$HOME/.local/share/Steam/steamapps/common/Aseprite/aseprite"
check "bitwig-studio" command -v bitwig-studio
check "PipeWire JACK (pipewire-jack)" pacman -Q pipewire-jack

printf '\n%d OK, %d FAIL\n' "$pass" "$fail"
exit "$fail"
