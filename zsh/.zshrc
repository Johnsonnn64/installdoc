# Created by newuser for 5.8.1
#
# zshrc
#

stty -ixon # disable ctrl-s ctrl-q
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt AUTOCD
setopt PROMPT_SUBST
ZPLUGINS=/home/john/.config/zsh/zplugins

# git status
autoload -U colors && colors
eval "$(starship init zsh)"
#PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}%(!.#.$) "

autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)
# movement for tab complete
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# vi-mode
bindkey -v
export KEYTIMEOUT=1
# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# lfcd
lfcd () {
  tmp="$(mktemp)"
  lf -command 'set dironly' -last-dir-path="$tmp" "$@"
  if [ -f "$tmp" ]; then
    dir="$(cat "$tmp")"
    rm -f "$tmp" >/dev/null
    [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
  fi
}

# fzf nvim
vfzf () {
  sel=$(fzf)
  if [[ ! -z $sel ]]; then
    nvim $sel
  fi
}

bindkey -s '^o' '^ulfcd\n'
bindkey -s '^e' 'vfzf\n'

~/.local/bin/fetch

alias ls="ls -F --color --group-directories-first"
alias ll="ls -AlFh --color --group-directories-first"
alias p="sudo pacman"
alias s="nsxiv -a" #opens sxiv image viewer
alias S="nsxiv * -tar" #opens whole folder with sxiv
alias ka="killall"
alias lf="lfrun"
alias g="git"
alias bat="bat --theme base16"
alias hib="systemctl hibernate"
alias his="systemctl hybrid-sleep"
alias lg="lazygit"
alias wget="wget --hsts-file='$XDG_CACHE_HOME/wget-hsts'"
if [ -e ~/.local/bin/monitor ]; then
  alias xrandr="monitor"
fi
# alias config="/usr/bin/git --git-dir=$HOME/workspace/git/dotfiles --work-tree=$HOME"
# alias website="/usr/bin/git --git-dir=$HOME/workspace/git/website --work-tree=$HOME/workspace/site"

# terminal timer/stopwatch
timer() {
    start="$(( $(date '+%s') + $1))"
    while [ $start -ge $(date +%s) ]; do
        time="$(( $start - $(date +%s) ))"
        printf '%s\r' "$(date -u -d "@$time" +%H:%M:%S)"
        sleep 0.1
    done
    notify-send -u critical "times up!" "timer for $(date -u -d "@$1" +%H:%M:%S)"
}

stopwatch() {
    start=$(date +%s)
    while true; do
        time="$(( $(date +%s) - $start))"
        printf '%s\r' "$(date -u -d "@$time" +%H:%M:%S)"
        sleep 0.1
    done
    notify-send "stopwatch" "$(date -u -d "@$time" +%H:%M:%S) spent"
}

# 'ls' after every 'cd'
if ! (( $chpwd_functions[(I)chpwd_cdls] )); then
  chpwd_functions+=(chpwd_cdls)
fi
function chpwd_cdls() {
  if [[ -o interactive ]]; then
    emulate -L zsh
    ls
  fi
}

# tty color
if [ "$TERM" = "linux" ]; then
	printf %b '\e]P01E1E2E' # set background color to "Base"
	printf %b '\e]P8585B70' # set bright black to "Surface2"

	printf %b '\e]P7BAC2DE' # set text color to "Text"
	printf %b '\e]PFA6ADC8' # set bright white to "Subtext0"

	printf %b '\e]P1F38BA8' # set red to "Red"
	printf %b '\e]P9F38BA8' # set bright red to "Red"

	printf %b '\e]P2A6E3A1' # set green to "Green"
	printf %b '\e]PAA6E3A1' # set bright green to "Green"

	printf %b '\e]P3F9E2AF' # set yellow to "Yellow"
	printf %b '\e]PBF9E2AF' # set bright yellow to "Yellow"

	printf %b '\e]P489B4FA' # set blue to "Blue"
	printf %b '\e]PC89B4FA' # set bright blue to "Blue"

	printf %b '\e]P5F5C2E7' # set magenta to "Pink"
	printf %b '\e]PDF5C2E7' # set bright magenta to "Pink"

	printf %b '\e]P694E2D5' # set cyan to "Teal"
	printf %b '\e]PE94E2D5' # set bright cyan to "Teal"

	clear
fi

# ---------- PLUGINS ----------
source $ZPLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZPLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh

# ---------- PLUGEND ----------
