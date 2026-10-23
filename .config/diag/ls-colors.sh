# shellcheck shell=bash
# Sourced by Bash after system shell setup. eza/ls have their own colour
# layer; terminal ANSI colours cannot override an RGB Mocha theme.
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"
# Prefer Diag over inherited LS_COLORS and legacy EXA_COLORS mappings.
export LS_COLORS='fi=38;2;196;201;206:di=38;2;23;147;209:ln=38;2;95;184;232:or=38;2;229;72;77:mi=38;2;229;72;77:ex=38;2;117;201;77:pi=38;2;255;176;0:so=38;2;23;147;209:bd=38;2;255;176;0:cd=38;2;255;176;0:su=38;2;229;72;77:sg=38;2;255;176;0:tw=38;2;255;176;0:ow=38;2;255;176;0:st=38;2;255;176;0'
# Disable eza's built-in extension rainbow; use the Diag YAML for metadata.
export EZA_COLORS='reset'
