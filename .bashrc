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

# Prompt: directory, git branch, red exit code when the last command failed
if [ -r /usr/share/git/completion/git-prompt.sh ]; then
  . /usr/share/git/completion/git-prompt.sh
  # shellcheck disable=SC2034  # read by git-prompt.sh
  GIT_PS1_SHOWDIRTYSTATE=1
fi
__prompt() {
  local code=$?
  local err=""
  [ "$code" -ne 0 ] && err="\[\e[31m\]$code \[\e[0m\]"
  local branch=""
  declare -F __git_ps1 >/dev/null && branch=$(__git_ps1 ' (%s)')
  PS1="${err}\[\e[34m\]\w\[\e[35m\]${branch}\[\e[0m\] \$ "
}
PROMPT_COMMAND="__prompt; $PROMPT_COMMAND"

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons --git-ignore'
alias grep='grep --color=auto'
alias v='nvim'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias ta='arena-dev'                                           # Pi Arena tmux session
alias cgcc='gcc -Wall -Wextra -g -fsanitize=address,undefined' # plan's default C flags
alias qa='qemu-aarch64'                                        # run ARM64 binaries on the desktop

[ -f "/home/sh0ds/.ghcup/env" ] && . "/home/sh0ds/.ghcup/env" # ghcup-env
# System info on new terminals, but not in every tmux pane or nvim terminal
if [[ -z $TMUX && -z $NVIM ]] && command -v fastfetch >/dev/null; then
  fastfetch
fi
eval "$(starship init bash)"
