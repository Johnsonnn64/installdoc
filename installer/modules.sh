# shellcheck shell=sh disable=SC2154
# Module implementations; variables/functions are supplied by common.sh.
build_suckless() {
    packages base-devel git libx11 libxinerama libxft fontconfig freetype2 libxcb xcb-util xcb-util-wm
    case $1 in
        dwm) source_dir=$SOURCE_ROOT/jondwm; url=https://github.com/JohnsoNNN64/jondwm; legacy=$HOME/workspace/suckless/jondwm; subdir=/dwm ;;
        dmenu) source_dir=$SOURCE_ROOT/dmenu; url=https://github.com/Johnsonnn64/dmenu; legacy=$HOME/workspace/suckless/dmenu; subdir= ;;
    esac
    checkout "$source_dir" "$url" "$legacy"
    run sh "$ROOT/installer/build.sh" "$source_dir$subdir" "$1" "$ROOT" "$BACKUP"
    if [ "$1" = dwm ]; then
        run sh "$ROOT/installer/bar.sh" "$source_dir" "$STATE"
        if [ -d "$source_dir/dwm/fonts" ] || "$dry_run"; then
            link "$source_dir/dwm/fonts" "$DATA/fonts/jondwm"
            run fc-cache -f
        fi
    fi
}
apply_module() {
    case $1 in
        desktop|steam) : ;;
        base)
            packages base-devel bc firefox man-db man-pages pacman-contrib playerctl powertop unzip words wget libnotify xdg-utils openssh
            run sudo systemctl enable --now paccache.timer
            printf '  fstrim.timer: enable manually after checking storage/discard support. Locale left unchanged.\n'
            ;;
        git) packages git lazygit ;;
        network)
            packages networkmanager
            system_file "$ROOT/system/networkmanager.conf" /etc/NetworkManager/conf.d/20-installdoc.conf
            if [ "$(readlink /etc/resolv.conf || :)" != /run/systemd/resolve/stub-resolv.conf ]; then
                if [ -e /etc/resolv.conf ] || [ -L /etc/resolv.conf ]; then
                    run sudo mkdir -p "/var/backups/installdoc/${BACKUP##*/}/etc"
                    run sudo cp -a /etc/resolv.conf "/var/backups/installdoc/${BACKUP##*/}/etc/resolv.conf"
                fi
                run sudo ln -sfT /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
            fi
            run sudo systemctl enable --now systemd-resolved NetworkManager
            run sudo nmcli general reload conf
            ;;
        xorg)
            packages xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset xorg-xsetroot xorg-xrdb xorg-xprop xorg-xinput xorg-xmodmap xf86-input-libinput xdotool xclip arandr scrot unclutter
            link "$ROOT/config/x11" "$CONFIG/x11"
            link "$ROOT/config/x11/xinitrc" "$HOME/.xinitrc"
            system_file "$ROOT/xserverrc" /etc/X11/xinit/xserverrc 755
            for script in screenshot monitor power.sh bookmarks; do link "$ROOT/config/bin/$script" "$HOME/.local/bin/$script"; done
            ;;
        dwm|dmenu) build_suckless "$1" ;;
        alacritty) packages alacritty mesa; link "$ROOT/alacritty.toml" "$CONFIG/alacritty.toml" ;;
        zsh)
            packages zsh starship zsh-autosuggestions zsh-syntax-highlighting fzf ripgrep
            link "$ROOT/config/zsh" "$HOME/.config/zsh"
            # The previous installer revision deployed this per-user override.
            if [ -L "$HOME/.zshenv" ] && [ "$(readlink "$HOME/.zshenv")" = "$ROOT/config/zshenv" ]; then backup "$HOME/.zshenv"; fi
            link "$ROOT/starship.toml" "$CONFIG/starship.toml"
            link "$ROOT/config/bin/fetch" "$HOME/.local/bin/fetch"
            run mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
            if [ -f "$HOME/.cache/zsh_history" ] && [ ! -e "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history" ]; then
                run cp -p "$HOME/.cache/zsh_history" "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
            fi
            # Expand HOME when zsh starts, not when printing this plan.
            # shellcheck disable=SC2016
            printf '  Migrate global ZDOTDIR to "$HOME/.config/zsh"; remove legacy duplicate profile sourcing, preserving unrelated settings.\n'
            run sudo sh "$ROOT/installer/zsh-migrate.sh" --apply "$ROOT" "/var/backups/installdoc/${BACKUP##*/}"
            if [ "$(getent passwd "$(id -un)" | cut -d: -f7)" != /usr/bin/zsh ]; then run sudo chsh -s /usr/bin/zsh "$(id -un)"; fi
            ;;
        root-config)
            printf '  Link /root/.config/{zsh,nvim} to shared sources; link Starship config.\n'
            printf '  Back up root conflicts and passwd; set root home=/root and shell=/usr/bin/zsh, without moving/chowning user data.\n'
            run sudo sh "$ROOT/installer/root-config.sh" "$ROOT" "$SOURCE_ROOT/gitnvim" "/var/backups/installdoc/${BACKUP##*/}/root-config"
            ;;
        dash)
            packages dash
            system_file "$ROOT/system/bash-update.hook" /etc/pacman.d/hooks/bash-update.hook
            if [ "$(readlink -f /usr/bin/sh)" != /usr/bin/dash ]; then
                run sudo mkdir -p "/var/backups/installdoc/${BACKUP##*/}/usr/bin"
                run sudo cp -a /usr/bin/sh "/var/backups/installdoc/${BACKUP##*/}/usr/bin/sh"
                run sudo ln -sfT dash /usr/bin/sh
            fi
            ;;
        pipewire)
            packages pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber pulsemixer libpulse
            run systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
            ;;
        fcitx)
            packages git fcitx5 fcitx5-gtk fcitx5-qt fcitx5-hangul fcitx5-mozc
            checkout "$SOURCE_ROOT/fcitx5" https://github.com/catppuccin/fcitx5.git
            link "$ROOT/config/fcitx5" "$CONFIG/fcitx5"
            link "$SOURCE_ROOT/fcitx5/src/catppuccin-mocha-blue" "$DATA/fcitx5/themes/catppuccin-mocha-blue"
            link "$ROOT/config/x11/input.sh" "$CONFIG/installdoc/input.sh"
            printf '  Input environment is loaded by the managed X session; restart X after deployment.\n'
            ;;
        keyd)
            packages keyd
            system_file "${KEYD_CONFIG:-/path/to/reviewed-keyd.conf}" /etc/keyd/default.conf
            run sudo systemctl enable keyd
            run sudo systemctl restart keyd
            ;;
        dunst) packages dunst; link "$ROOT/dunstrc" "$CONFIG/dunst/dunstrc" ;;
        picom) packages picom; link "$ROOT/config/picom.conf" "$CONFIG/picom/picom.conf" ;;
        feh) packages feh; printf '  X session uses ~/personal/pictures/wall.png, with a black fallback.\n' ;;
        clipmenu)
            packages clipmenu
            if "$dry_run" || systemctl --user cat clipmenud.service >/dev/null 2>&1; then
                run systemctl --user disable --now clipmenud.service
            fi
            printf '  clipmenud is owned by the X session.\n'
            ;;
        lf)
            packages lf ueberzugpp jq file chafa
            aur dragon-drop
            link "$ROOT/config/lf" "$CONFIG/lf"
            link "$ROOT/config/bin/lfrun" "$HOME/.local/bin/lfrun"
            link "$ROOT/bin/dragon-dl" "$HOME/.local/bin/dragon-dl"
            ;;
        cli)
            packages ncdu btop fzf ripgrep zathura zathura-pdf-poppler
            link "$ROOT/zathura" "$CONFIG/zathura"
            ;;
        neovim)
            packages git neovim ripgrep unzip base-devel
            checkout "$SOURCE_ROOT/gitnvim" https://github.com/Johnsonnn64/gitnvim "$CONFIG/nvim"
            run sh "$ROOT/installer/neovim-migrate.sh" "$SOURCE_ROOT/gitnvim" "$ROOT/installer/patches/gitnvim-shared-home.patch" "$BACKUP/neovim-migration"
            link "$SOURCE_ROOT/gitnvim" "$CONFIG/nvim"
            ;;
        fonts)
            packages adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts ttf-hanazono ttf-jetbrains-mono-nerd
            aur ttf-joypixels
            run fc-cache -f
            ;;
        polkit)
            packages polkit lxqt-policykit xdg-desktop-portal xdg-desktop-portal-gtk
            link "$ROOT/config/portals.conf" "$CONFIG/xdg-desktop-portal/portals.conf"
            ;;
        bluetooth)
            packages bluez bluez-utils
            link "$ROOT/bin/bluetoothdmenu.sh" "$HOME/.local/bin/bluetoothdmenu.sh"
            run sudo systemctl enable --now bluetooth
            ;;
        easyeffects)
            packages easyeffects
            link "$ROOT/optional/easyeffects" "$CONFIG/easyeffects"
            link "$ROOT/config/easyeffects-enabled" "$CONFIG/installdoc/easyeffects-enabled"
            ;;
        media) packages nsxiv mpv ;;
        *) die "No implementation for $1" ;;
    esac
}
