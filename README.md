# dotfiles

Hyprland 0.55+ (Lua config), kitty, tmux, Neovim 0.12 + LazyVim, waybar, mako, fuzzel, hyprlock, hypridle. Catppuccin Mocha throughout. Made for the Pi Arena desktop; the full walkthrough is `arch-hyprland-install-guide.md` in the project.

```bash
git clone https://github.com/sh0ds/dotfiles.git ~/code/dotfiles
bash ~/code/dotfiles/install-dotfiles.sh    # symlinks into $HOME, backs up what was there
bash ~/code/dotfiles/check-desktop.sh       # 0 FAIL when the desktop is complete
```

Edit files through the symlinks, then `git diff` / commit here.
