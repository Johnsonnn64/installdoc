# /etc/zsh/zshenv selects this shared directory separately for each account.
# Root must not inherit the invoking user's XDG runtime paths via sudo -E.
if (( EUID == 0 )); then
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_CACHE_HOME="$HOME/.cache"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
else
  export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
  export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
  export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
  export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
fi
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=99999 SAVEHIST=99999
export EDITOR=nvim
# zsh's unique path array prevents duplicate entries in nested/login shells.
typeset -U path PATH
path=("$HOME/.local/bin" $path)
