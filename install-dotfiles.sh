#!/usr/bin/env bash
# install-dotfiles.sh: link configs into $HOME; render Qt and copy writable configs.
# Existing files are moved to ~/.dotfiles-backup/<time>/ first, never deleted.
# Symlinks mean an edit in ~/.config/... is an edit in this repo: commit it.
# Usage: bash install-dotfiles.sh          (run from anywhere)
#        bash install-dotfiles.sh --target /tmp/diag-preview (isolated install)
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
target_home=$HOME
if [ "$#" -ne 0 ]; then
  if [ "$#" -ne 2 ] || [ "$1" != --target ] || [[ $2 != /* ]]; then
    echo "Usage: $0 [--target /absolute/directory]" >&2
    exit 2
  fi
  target_home=$2
fi
mkdir -p "$target_home"
target_home=$(cd "$target_home" && pwd -P)
case "$target_home/" in "$src/"*) echo "Target must be outside the checkout" >&2; exit 2 ;; esac

# qt6ct requires an absolute palette path and does not expand ~ or $HOME.
# Render only this small config; keep all theme assets linked to the repo.
qt_config=$(mktemp)
trap 'rm -f "$qt_config"' EXIT
while IFS= read -r line || [ -n "$line" ]; do
  if [[ $line == *@CONFIG_HOME@* ]]; then
    printf '%s%s%s\n' "${line%%@CONFIG_HOME@*}" "$target_home/.config" "${line#*@CONFIG_HOME@}"
  else
    printf '%s\n' "$line"
  fi
done <"$src/.config/qt6ct/qt6ct.conf" >"$qt_config"

cd "$src"
# Only files git tracks, so nothing local or half-finished gets linked.
git ls-files | grep -vE '^(install-dotfiles\.sh|check-desktop\.sh|README\.md|LICENSE|\.gitignore|screenshots/|docs/|system/|tests/)' |
  while IFS= read -r rel; do
  target="$target_home/$rel"
  config_source=$src/$rel
  copy_config=0
  case $rel in
    .config/qt6ct/qt6ct.conf) config_source=$qt_config; copy_config=1 ;;
    .config/btop/btop.conf) copy_config=1 ;; # btop rewrites this on exit
    .config/nchat/color.conf) copy_config=1 ;; # keep app writes out of the repo
  esac
  if [ "$copy_config" = 1 ] && [ ! -L "$target" ] && cmp -s "$config_source" "$target"; then
    echo "ok      $rel"
    continue
  fi
  if [ "$copy_config" = 0 ] && [ -L "$target" ] && [ "$(readlink "$target")" = "$src/$rel" ]; then
    echo "ok      $rel"
    continue
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ -z "${backup:-}" ]; then
      mkdir -p "$target_home/.dotfiles-backup"
      backup=$(mktemp -d "$target_home/.dotfiles-backup/$(date +%Y%m%d-%H%M%S).XXXXXX")
    fi
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$target" "$backup/$rel"
    echo "backup  $rel"
  fi
  mkdir -p "$(dirname "$target")"
  if [ "$copy_config" = 1 ]; then
    install -m 644 "$config_source" "$target"
  else
    ln -s "$src/$rel" "$target"
  fi
  echo "linked  $rel"
done

# Files that were deleted from the repo leave dead links behind: remove them.
{ find "$target_home" -maxdepth 1 -xtype l -lname "$src/*"
  find "$target_home/.config" "$target_home/.local/bin" -xtype l -lname "$src/*" 2>/dev/null; } |
  while IFS= read -r dead; do rm "$dead"; echo "removed ${dead#"$target_home"/}"; done

chmod +x "$src/.local/bin/"*
mkdir -p "$target_home/Pictures"
echo
echo "Done. Backups (if any) are in $target_home/.dotfiles-backup/"
