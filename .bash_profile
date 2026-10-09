# ~/.bash_profile
[ -f ~/.bashrc ] && . ~/.bashrc

# Start Hyprland when you log in on the first console. Skipped under a display
# manager such as SDDM (session type is then "wayland", not "tty"), so this is
# just a fallback when SDDM is disabled.
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "${XDG_SESSION_TYPE:-}" = tty ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
  if command -v start-hyprland >/dev/null; then
    exec start-hyprland
  else
    exec Hyprland
  fi
fi
