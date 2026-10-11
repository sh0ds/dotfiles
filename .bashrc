# ~/.bashrc
[[ $- != *i* ]] && return

# PATH: your scripts, then GHCup (Haskell)
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"

export EDITOR=nvim
export VISUAL=nvim
export MANPAGER="nvim +Man!"

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

# History: big, shared between tmux panes, no duplicates
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize globstar
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons --git-ignore'
alias grep='grep --color=auto'
alias v='nvim'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias ta='arena-dev'                                           # Pi Arena tmux session
alias cgcc='gcc -Wall -Wextra -g -fsanitize=address,undefined' # C with warnings and sanitizers
alias qa='qemu-aarch64'                                        # run ARM64 binaries on the desktop

please() {
  local c
  c=$(fc -ln -2 -1 | grep -v '^[[:space:]]*please' | tail -n1)
  c=${c#"${c%%[![:space:]]*}"}
  [ -n "$c" ] || return 1
  printf '\e[35mfine. sudo %s\e[0m\n' "$c"
  eval "sudo $c"
}

# System info on new terminals, but not in every tmux pane or nvim terminal
if [[ -z $TMUX && -z $NVIM ]] && command -v fastfetch >/dev/null; then
  fastfetch
fi
eval "$(starship init bash)"                     # prompt
eval "$(fzf --bash)"                             # Ctrl+R fuzzy history, Ctrl+T file path, Alt+C cd into a folder
eval "$(zoxide init bash)"                       # z arena jumps to ~/code/pi-arena; zi picks from a list
