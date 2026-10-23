#!/usr/bin/env bash
# install-dotfiles.sh: symlink every config in this repo into $HOME.
# Existing files are moved to ~/.dotfiles-backup/<time>/ first, never deleted.
# Symlinks mean an edit in ~/.config/... is an edit in this repo: commit it.
# Usage: bash install-dotfiles.sh          (run from anywhere)
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

cd "$src"
# Only files git tracks, so nothing local or half-finished gets linked.
git ls-files | grep -vE '^(install-dotfiles\.sh|check-desktop\.sh|README\.md|LICENSE|\.gitignore|screenshots/|docs/|system/)' |
  while IFS= read -r rel; do
  target="$HOME/$rel"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src/$rel" ]; then
    echo "ok      $rel"
    continue
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$target" "$backup/$rel"
    echo "backup  $rel"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$src/$rel" "$target"
  echo "linked  $rel"
done

# Files that were deleted from the repo leave dead links behind: remove them.
{ find "$HOME" -maxdepth 1 -xtype l -lname "$src/*"
  find "$HOME/.config" "$HOME/.local/bin" -xtype l -lname "$src/*" 2>/dev/null; } |
  while IFS= read -r dead; do rm "$dead"; echo "removed ${dead#"$HOME"/}"; done

chmod +x "$src/.local/bin/"*
# VT323 (the bar, lock screen, launcher and notifications) ships in this repo
command -v fc-cache >/dev/null && fc-cache -f "$HOME/.local/share/fonts" >/dev/null
mkdir -p "$HOME/Pictures"
echo
echo "Done. Backups (if any) are in $HOME/.dotfiles-backup/"
