#!/usr/bin/env bash
# install-dotfiles.sh: symlink every config in this repo into $HOME.
# Existing files are moved to ~/.dotfiles-backup/<time>/ first, never deleted.
# Symlinks mean an edit in ~/.config/... is an edit in this repo: commit it.
# Usage: bash install-dotfiles.sh          (run from anywhere)
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

cd "$src"
find . -type f \
  ! -path './.git/*' ! -name 'install-dotfiles.sh' ! -name 'check-desktop.sh' ! -name 'README.md' \
  -printf '%P\n' | sort | while IFS= read -r rel; do
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

chmod +x "$src/.local/bin/"*
mkdir -p "$HOME/Pictures"
echo
echo "Done. Backups (if any) are in $HOME/.dotfiles-backup/"
