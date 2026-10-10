#
# zprofile
#

# user dirs
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# clean up (https://wiki.archlinux.org/title/XDG_Base_Directory)
export XINITRC="$XDG_CONFIG_HOME/x11/xinitrc"
export GOPATH="$XDG_DATA_HOME/go"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
  export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
fi
# export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export LESSHISTFILE=-
export WINIT_X11_SCALE_FACTOR=1 # alacritty dpi scaling
# export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
# export SSB_HOME="$XDG_DATA_HOME"/zoom
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export NUGET_PACKAGES="$XDG_DATA_HOME/NuGetPackages"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export CODEX_HOME="$XDG_DATA_HOME/codex"

# etc
export EDITOR="nvim"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=16,border:4"
export FZF_DEFAULT_COMMAND="rg --files --hidden -g !.git"
[ ! -r /etc/locale.conf ] || source /etc/locale.conf

# Input environment is enabled by the fcitx module.
if [ -r "$XDG_CONFIG_HOME/installdoc/input.sh" ]; then
  source "$XDG_CONFIG_HOME/installdoc/input.sh"
fi

# zsh history
export HIST_STAMPS="yyyy/mm/dd"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
export HISTSIZE=99999
export SAVEHIST=99999

# Normal-user interactive tty1 login only; never root or SSH.
if [[ -o interactive && $EUID -ne 0 && -z ${DISPLAY:-} && -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} && -r "$XINITRC" ]] && [[ "$(tty)" = /dev/tty1 ]] && command -v startx >/dev/null; then
  exec startx "$XINITRC"
fi
