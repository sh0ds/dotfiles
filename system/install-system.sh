#!/usr/bin/env bash
# install-system.sh: the parts of the Diag look that live outside $HOME and
# need root: the SDDM login screen and the Plymouth boot splash.
# Usage: bash ~/code/dotfiles/system/install-system.sh   (asks for sudo)
# Run it again after changing anything under system/. Old configs it replaces
# are moved to /etc/sddm.conf.d/old/, never deleted.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# ---- SDDM: the Diag theme (Qt 6, runs on weston like before) ----
t=/usr/share/sddm/themes/diag
sudo install -d "$t"
sudo install -m 644 "$here"/sddm/diag/{Main.qml,metadata.desktop,theme.conf} "$t/"
sudo install -m 644 "$repo/.local/share/fonts/VT323-Regular.ttf" "$repo/.config/hypr/arch-logo.png" "$t/"
sudo install -d /etc/sddm.conf.d
for old in /etc/sddm.conf.d/*.conf; do
  [ -e "$old" ] || continue
  [ "$old" = /etc/sddm.conf.d/10-diag.conf ] && continue
  if grep -q '^Current=' "$old"; then
    sudo install -d /etc/sddm.conf.d/old
    sudo mv "$old" /etc/sddm.conf.d/old/
    echo "moved $old to /etc/sddm.conf.d/old/"
  fi
done
sudo tee /etc/sddm.conf.d/10-diag.conf >/dev/null <<'CONF'
# Written by dotfiles/system/install-system.sh
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=weston --shell=kiosk

[Theme]
Current=diag
CursorTheme=Adwaita
CONF
echo "SDDM: diag theme installed"

# ---- Plymouth: the Diag boot splash ----
if command -v plymouth-set-default-theme >/dev/null; then
  p=/usr/share/plymouth/themes/diag
  sudo install -d "$p"
  sudo install -m 644 "$here"/plymouth/diag/* "$p/"
  sudo plymouth-set-default-theme -R diag    # -R rebuilds the initramfs
  echo "Plymouth: diag splash installed"
else
  echo "Plymouth isn't installed, skipped the boot splash"
fi

echo "Done. The login screen and splash show on the next boot."
echo "Preview the login screen without rebooting: sddm-greeter-qt6 --test-mode --theme $t"
