#!/usr/bin/env bash
# install-system.sh: the parts of the Afterhours look that live outside $HOME and
# need root: the SDDM login screen, the Plymouth boot splash, the picture
# the kernel image shows before it and the early boot that gets the splash
# on screen in time.
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
# The login opens from the boot splash's mark, so it needs the same picture.
sudo install -m 644 "$here/plymouth/afterhours/logo.png" "$t/logo.png"
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
# weston's own backdrop is the charcoal of the splash instead of black, so
# nothing flashes between the splash and the login.
printf '# Written by dotfiles/system/install-system.sh\n[shell]\nbackground-color=0xff0d0c10\n\n[keyboard]\nkeymap_layout=%s\n' "${layout:-de}" >"$ini"
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
# The splash normally waits for the real graphics driver. With NVIDIA that
# one loads so late that the splash gets a fraction of a second, and all you
# see before the login is the still picture. This option lets it draw on the
# screen the firmware set up, from the first moment, on the same pixels as
# that picture.
cmdline=/etc/kernel/cmdline
if grep -qs '_uki=' /etc/mkinitcpio.d/*.preset && [ -f "$cmdline" ] \
   && [ "$(wc -l <"$cmdline")" -le 1 ] && grep -qw splash "$cmdline" \
   && ! grep -q 'plymouth\.use-simpledrm' "$cmdline"; then
  [ -e "$cmdline.before-afterhours" ] || sudo cp "$cmdline" "$cmdline.before-afterhours"
  sudo sed -i '1s/[[:space:]]*$/ plymouth.use-simpledrm/' "$cmdline"
  echo "Boot: the splash starts right away (plymouth.use-simpledrm)"
  rebuild=1
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

# ---- Early boot: start in parallel, NVIDIA up at once ----
# Measured on this PC: the stock early boot (busybox, the udev hook) waits
# about 4 s for every USB device before it mounts the disk or starts the
# splash, and the NVIDIA driver, the only one with a screen attached, loads
# after that. The splash got a quarter of a second. With systemd in the
# early boot nothing waits for USB, and with the NVIDIA modules inside the
# kernel image the splash has a real screen within about a second.
# The kms hook goes: it only brought nouveau and the Intel driver (no screen
# on that one) into the image.
# Written as a drop-in, so /etc/mkinitcpio.conf stays as it is. The kernel
# image you booted with is kept as a second menu entry in case the new one
# doesn't come up: hold Space at power-on and pick the "before" entry.
# Undo:  sudo rm /etc/mkinitcpio.conf.d/afterhours.conf && sudo mkinitcpio -P
drop=/etc/mkinitcpio.conf.d/afterhours.conf
stock_hooks='base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck'
early_hooks='base systemd plymouth autodetect microcode modconf keyboard sd-vconsole block filesystems fsck'
early_boot() {
  [ -e "$drop" ] && return 0
  grep -qs '_uki=' /etc/mkinitcpio.d/*.preset && [ -n "$esp" ] && sudo test -f "$loader" || return 0
  local hooks modules k entry avail size
  hooks=$(sed -n 's/^HOOKS=(\(.*\))[[:space:]]*$/\1/p' /etc/mkinitcpio.conf | tail -1)
  modules=$(sed -n 's/^MODULES=(\(.*\))[[:space:]]*$/\1/p' /etc/mkinitcpio.conf | tail -1)
  if [ "$hooks" != "$stock_hooks" ] || [ -n "$modules" ]; then
    echo "Early boot: mkinitcpio.conf isn't the stock one, left alone"; return 0
  fi
  for k in /usr/lib/modules/*/; do
    [ -e "$k/pkgbase" ] || continue
    if ! modinfo -k "$(basename "$k")" nvidia_drm >/dev/null 2>&1; then
      echo "Early boot: no NVIDIA module for kernel $(basename "$k"), left alone"; return 0
    fi
  done
  # systemd-boot leaves the name of the entry it started in the firmware.
  entry=$(tail -c +5 /sys/firmware/efi/efivars/LoaderEntrySelected-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f 2>/dev/null | tr -d '\0' || true)
  if [ -z "$entry" ] || ! sudo test -f "$esp/EFI/Linux/$entry"; then
    echo "Early boot: can't tell which kernel image this boot used, left alone"; return 0
  fi
  size=$(sudo du -k "$esp/EFI/Linux/$entry" | cut -f1)
  avail=$(df -k --output=avail "$esp" | tail -1)
  if [ "$avail" -lt $((size * 3)) ]; then
    echo "Early boot: not enough room on $esp for a fallback image, left alone"; return 0
  fi
  sudo cp "$esp/EFI/Linux/$entry" "$esp/EFI/Linux/${entry%.efi}-before-afterhours.efi"
  # Two images of the same kernel now: say which one starts by default.
  sudo sed -i -E '/^[[:space:]]*default[[:space:]]/d' "$loader"
  echo "default $entry" | sudo tee -a "$loader" >/dev/null
  sudo bootctl set-default "$entry" >/dev/null
  sudo install -d /etc/mkinitcpio.conf.d
  printf '%s\n' '# Written by dotfiles/system/install-system.sh (see "Early boot" there)' \
    'MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)' "HOOKS=($early_hooks)" |
    sudo tee "$drop" >/dev/null
  echo "Early boot: systemd hooks and early NVIDIA; fallback entry ${entry%.efi}-before-afterhours.efi"
  rebuild=1
}
early_boot

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

if [ -n "${esp:-}" ] && sudo test -d "$esp/EFI/Linux"; then
  echo "Kernel images on $esp:"
  sudo ls -l "$esp/EFI/Linux" | awk 'NR > 1 { printf "  %4d MB  %s\n", $5 / 1048576, $NF }'
fi
echo "Done. The login screen and splash show on the next boot."
echo "Preview the login screen without rebooting: sddm-greeter-qt6 --test-mode --theme $t"
