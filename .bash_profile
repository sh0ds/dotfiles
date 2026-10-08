# ~/.bash_profile
[ -f ~/.bashrc ] && . ~/.bashrc

# Start Hyprland when you log in on the first console (no display manager needed).
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
  if command -v start-hyprland >/dev/null; then
    exec start-hyprland
  else
    exec Hyprland
  fi
fi
