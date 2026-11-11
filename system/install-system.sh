#!/usr/bin/env bash
# install-system.sh: the parts of the Afterhours look that live outside $HOME and
# need root: the SDDM login screen, the Plymouth boot splash and the picture
# the kernel image shows before it.
# Usage: bash ~/code/dotfiles/system/install-system.sh   (asks for sudo)
# Run it again after changing anything under system/. Old configs it replaces
# are moved to /etc/sddm.conf.d/old/, never deleted.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# ---- SDDM: the Afterhours theme (Qt 6, runs on weston like before) ----
# The greeter runs as the sddm user and can't read $HOME, so the wallpaper
# is copied in as background.jpg.
t=/usr/share/sddm/themes/afterhours
sudo install -d "$t"
sudo install -m 644 "$here"/sddm/afterhours/{Main.qml,metadata.desktop,theme.conf} "$t/"
sudo install -m 644 "$repo/.local/share/backgrounds/afterhours-haze.jpg" "$t/background.jpg"
sudo rm -f "$t/background.png"
# The old Diag theme is gone from the repo; drop its installed copy too.
sudo rm -rf /usr/share/sddm/themes/diag
sudo install -d /etc/sddm.conf.d
for old in /etc/sddm.conf.d/*.conf; do
  [ -e "$old" ] || continue
  [ "$old" = /etc/sddm.conf.d/10-afterhours.conf ] && continue
  if grep -q '^Current=' "$old"; then
    sudo install -d /etc/sddm.conf.d/old
    sudo mv "$old" /etc/sddm.conf.d/old/
    echo "moved $old to /etc/sddm.conf.d/old/"
  fi
done
sudo tee /etc/sddm.conf.d/10-afterhours.conf >/dev/null <<'CONF'
# Written by dotfiles/system/install-system.sh
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=weston --shell=kiosk

[Theme]
Current=afterhours
CursorTheme=Posy_Cursor_Black
CursorSize=32
CONF
echo "SDDM: afterhours theme installed"

# weston's kiosk shell puts the greeter on whichever screen it finds first
# (DP-3 here), so switch every other connected screen off while it runs. The
# screens come back as soon as Hyprland starts. Run this again after plugging
# in a new screen.
main=DP-4
layout=$(localectl status 2>/dev/null | sed -n 's/.*X11 Layout: *//p')
ini=$(mktemp)
printf '# Written by dotfiles/system/install-system.sh\n[keyboard]\nkeymap_layout=%s\n' "${layout:-de}" >"$ini"
for s in /sys/class/drm/card*-*/status; do
  [ "$(cat "$s")" = connected ] || continue
  name=$(basename "$(dirname "$s")"); name=${name#card*-}
  [ "$name" = "$main" ] && continue
  printf '\n[output]\nname=%s\nmode=off\n' "$name" >>"$ini"
  echo "SDDM: $name off at the login screen"
done
sudo install -d -o sddm -g sddm /var/lib/sddm/.config
sudo install -m 644 -o sddm -g sddm "$ini" /var/lib/sddm/.config/weston.ini
rm "$ini"

# ---- Boot: the Afterhours mark from the first second, no menu flash ----
# For systemd-boot with unified kernel images (mkinitcpio presets that have
# --splash). The picture inside the kernel image shows until the splash
# takes over; Arch's default is its own logo. Ours is the splash's mark on
# the same pixels, so the two blend into one.
# The boot menu is text only and can't be themed, so it stays hidden. To
# get it (for the LTS kernel): hold Space while the PC starts, or run
#   systemctl reboot --boot-loader-menu=10
# Undo: the files this changes are kept next to them as *.before-afterhours.
bmp=/usr/local/share/afterhours/splash-afterhours.bmp
arch_bmp=/usr/share/systemd/bootctl/splash-arch.bmp
rebuild=0
if grep -qs -- "--splash" /etc/mkinitcpio.d/*.preset; then
  sudo install -D -m 644 "$here/boot/splash-afterhours.bmp" "$bmp"
  for preset in /etc/mkinitcpio.d/*.preset; do
    grep -q -- "--splash $arch_bmp" "$preset" || continue
    [ -e "$preset.before-afterhours" ] || sudo cp "$preset" "$preset.before-afterhours"
    sudo sed -i "s|--splash $arch_bmp|--splash $bmp|" "$preset"
    echo "Boot: $(basename "$preset" .preset) shows the Afterhours mark"
    rebuild=1
  done
else
  echo "Boot: no kernel image with a built-in picture here, skipped"
fi
esp=$(sudo bootctl --print-esp-path 2>/dev/null || true)
loader=$esp/loader/loader.conf
if [ -n "$esp" ] && sudo test -f "$loader"; then
  if ! sudo grep -qx 'timeout 0' "$loader"; then
    sudo test -e "$loader.before-afterhours" || sudo cp "$loader" "$loader.before-afterhours"
    sudo sed -i -E '/^[[:space:]]*timeout[[:space:]]/d' "$loader"
    echo 'timeout 0' | sudo tee -a "$loader" >/dev/null
    echo "Boot: the menu is hidden (hold Space at power-on to see it)"
  fi
  # A timeout once set from inside the menu (keys t, + and -) is kept by the
  # firmware and wins over loader.conf, so hide the menu there as well.
  var=/sys/firmware/efi/efivars/LoaderConfigTimeout-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f
  if [ -e "$var" ] && [ "$(tail -c +5 "$var" | tr -d '\0')" != 0 ]; then
    sudo bootctl set-timeout 0 >/dev/null && echo "Boot: cleared the menu timeout stored in the firmware"
  fi
else
  echo "Boot: systemd-boot isn't the boot loader here, menu left alone"
fi

# ---- Plymouth: the Afterhours boot splash ----
if command -v plymouth-set-default-theme >/dev/null; then
  p=/usr/share/plymouth/themes/afterhours
  sudo install -d "$p"
  sudo install -m 644 "$here"/plymouth/afterhours/* "$p/"
  sudo plymouth-set-default-theme -R afterhours    # -R rebuilds the initramfs
  sudo rm -rf /usr/share/plymouth/themes/diag
  echo "Plymouth: afterhours splash installed"
else
  echo "Plymouth isn't installed, skipped the boot splash"
  # Nothing rebuilt the kernel images yet, so the new picture isn't in them.
  if [ "$rebuild" = 1 ]; then sudo mkinitcpio -P; fi
fi

# ---- Icons: Papirus with violet folders (papirus-folders recolours the
# installed theme in place, so it needs root and survives until the next
# papirus-icon-theme update; run this script again after one) ----
if command -v papirus-folders >/dev/null; then
  sudo papirus-folders -C violet --theme Papirus-Dark && echo "Icons: Papirus folders are violet"
else
  echo "papirus-folders isn't installed (yay -S papirus-folders), folders keep Papirus blue"
fi

echo "Done. The login screen and splash show on the next boot."
echo "Preview the login screen without rebooting: sddm-greeter-qt6 --test-mode --theme $t"
