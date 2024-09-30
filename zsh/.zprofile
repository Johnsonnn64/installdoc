#
# zprofile
#

# user dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export PATH="$PATH:$HOME/.local/bin"

# clean up
export XINITRC="$XDG_CONFIG_HOME/x11/xinitrc"
export GOPATH="$XDG_DATA_HOME/go"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
# export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export LESSHISTFILE=-
export WINIT_X11_SCALE_FACTOR=1 # alacritty dpi scaling
# export WGETRC="$XDG_CONFIG_HOME/wgetrc"
# export npm_config_prefix="$HOME/.local/"
# export SSB_HOME="$XDG_DATA_HOME"/zoom

# etc
export EDITOR="nvim"
export $(dbus-launch)
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=16,border:4"
export FZF_DEFAULT_COMMAND="fd --hidden --exclude .git"
source /etc/locale.conf

# fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# zsh history
export HIST_STAMPS="yyyy/mm/dd"
export HISTFILE="$HOME/.cache/zsh_history"
export HISTSIZE=99999
export SAVEHIST=99999

# autostart xserver
if [ "$(tty)" = "/dev/tty1" ]; then
  # pgrep -x dwm || exec startx ~/.config/x11/xinitrc
  # hyprland_launch
fi
