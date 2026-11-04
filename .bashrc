# ~/.bashrc
[[ $- != *i* ]] && return

# PATH: your scripts, then GHCup (Haskell)
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"
# Emscripten (emcc) and itch.io's butler: Arch's emscripten only adds itself
# to PATH in login shells, and butler lives in its own folder.
[ -d /usr/lib/emscripten ] && PATH="$PATH:/usr/lib/emscripten"
[ -d "$HOME/.local/opt/butler" ] && PATH="$PATH:$HOME/.local/opt/butler"

export EDITOR=helix
export VISUAL=helix
export MANPAGER="sh -c 'col -bx | bat -l man -p'"   # man pages in bat's colours
export MANROFFOPT="-c"

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

# History: big, shared between terminals, no duplicates
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize globstar
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# File listings use Afterhours independently of kitty's ANSI palette.
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/diag/ls-colors.sh" ]; then
  . "${XDG_CONFIG_HOME:-$HOME/.config}/diag/ls-colors.sh"
fi

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons --git-ignore'
alias grep='grep --color=auto'
alias hx='helix'
alias v='helix'                                               # quick edits in the terminal
alias zed='zeditor'                                           # the editor for projects
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias cgcc='gcc -Wall -Wextra -g -fsanitize=address,undefined' # C with warnings and sanitizers
alias qa='qemu-aarch64'                                        # run ARM64 binaries on the desktop
alias lg='lazygit'                                              # git TUI (Ctrl+G in Helix)
alias cat='bat --paging=never --style=plain'                   # cat with colours; plain `bat` gets line numbers
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :200 {}'"
# fzf in Afterhours: violet matches and pointer, soft selection, rounded border
export FZF_DEFAULT_OPTS="--border=rounded --color=fg:#c9c5d4,bg:-1,hl:#b49cf0,fg+:#ecebf2,bg+:#1b1a22,hl+:#cdbcf7,info:#948fa3,prompt:#948fa3,pointer:#b49cf0,marker:#b49cf0,spinner:#b49cf0,header:#948fa3,border:#25232d,gutter:-1"

please() {
  local c
  c=$(fc -ln -2 -1 | grep -v '^[[:space:]]*please' | tail -n1)
  c=${c#"${c%%[![:space:]]*}"}
  [ -n "$c" ] || return 1
  printf '\e[35mfine. sudo %s\e[0m\n' "$c"
  eval "sudo $c"
}

alias yeet='git push'
alias yoink='git pull'

make() { if [ "$*" = "me a sandwich" ]; then echo "What? Make it yourself."; else command make "$@"; fi; }
sudo() { if [ "$*" = "make me a sandwich" ]; then echo "Okay."; else command sudo "$@"; fi; }

command_not_found_handle() {
  case $1 in
    claer|clera|cler) printf '\e[35mclose enough\e[0m\n'; sleep 0.6; clear ;;
    exti|eixt|exot|:q|:wq) printf '\e[35mthis is not vim. but okay, bye\e[0m\n'; sleep 0.8; kill -HUP $$ ;;  # runs in a subshell, so plain exit wouldn't close the terminal
    gti|gut|tig) printf '\e[35m%s? sure, git\e[0m\n' "$1"; shift; git "$@" ;;
    hello|hi|hey) printf '\e[35mhi %s\e[0m\n' "$USER" ;;
    fuck|wtf) printf '\e[35mlanguage.\e[0m\n' ;;
    matrix|cmatrix) printf '\e[32mthere is no spoon.\e[0m\n' ;;
    hack|hackerman)
      for p in 12 47 83 100; do printf '\r\e[32mhacking the mainframe... %s%%\e[0m' "$p"; sleep 0.4; done
      printf "\n\e[32mI'm in.\e[0m\n" ;;
    coffee) printf '\e[35mthe terminal does not make coffee. yet.\e[0m\n' ;;
    *)
      local quips=("nope" "never heard of it" "did you mean: touch grass" "that's not a thing (yet)" "skill issue"
                   "bold of you to assume that exists" "typo or vibes?" "404")
      if ((SRANDOM % 5 == 0)); then  # SRANDOM: RANDOM repeats in this subshell
        printf '\e[35m%s: %s\e[0m\n' "$1" "${quips[SRANDOM % ${#quips[@]}]}" >&2
      else
        printf 'bash: %s: command not found\n' "$1" >&2
      fi
      return 127 ;;
  esac
}

# System info on new terminals
if command -v fastfetch >/dev/null; then
  fastfetch
  case $(date +%m-%d) in
    01-01)       printf '\e[35mhappy new year. same bugs as last year though.\e[0m\n' ;;
    04-01)       printf '\e[35mnothing you read today is true.\e[0m\n' ;;
    10-31)       printf '\e[35mboo.\e[0m\n' ;;
    12-24|12-25) printf '\e[35mmerry christmas. close the laptop.\e[0m\n' ;;
  esac
fi
eval "$(starship init bash)"                     # prompt
eval "$(fzf --bash)"                             # Ctrl+R fuzzy history, Ctrl+T file path, Alt+C cd into a folder
eval "$(zoxide init bash)"                       # z website jumps to ~/code/website; zi picks from a list
alias e=hx
