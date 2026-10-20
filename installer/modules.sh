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
# Gaming selection and repository checks run during preflight, before mutations.
gaming_add() {
    for gaming_package do
        case " $gaming_packages " in
            *" $gaming_package "*) ;;
            *) gaming_packages="${gaming_packages:+$gaming_packages }$gaming_package" ;;
        esac
    done
}
gaming_plan() {
    [ -n "${GAMING_GPU:-}" ] || die 'Set GAMING_GPU to amd, intel, or nvidia (space-separated for hybrid GPUs).'
    case $GAMING_GPU in *[!a-z\ ]*) die 'GAMING_GPU must contain space-separated GPU names.' ;; esac
    case ${GAMING_EXTRAS:-} in *[!a-z\ ]*) die 'GAMING_EXTRAS must contain space-separated tool names.' ;; esac
    gaming_packages=
    gaming_nvidia=false
    for gaming_gpu in $GAMING_GPU; do
        case $gaming_gpu in
            amd) gaming_add mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon ;;
            intel) gaming_add mesa lib32-mesa vulkan-intel lib32-vulkan-intel ;;
            nvidia)
                gaming_nvidia=true
                gaming_add nvidia-utils lib32-nvidia-utils
                ;;
            *) die "Unsupported GAMING_GPU: $gaming_gpu" ;;
        esac
    done
    [ -n "$gaming_packages" ] || die 'GAMING_GPU must select at least one GPU.'
    gaming_add vulkan-icd-loader lib32-vulkan-icd-loader lib32-libpulse steam
    for gaming_extra in ${GAMING_EXTRAS:-}; do
        case $gaming_extra in
            gamemode) gaming_add gamemode lib32-gamemode ;;
            mangohud) gaming_add mangohud lib32-mangohud ;;
            *) die "Unsupported GAMING_EXTRAS tool: $gaming_extra (choose gamemode, mangohud)" ;;
        esac
    done
}
gaming_preflight() {
    gaming_plan
    gaming_ready=true
    if ! command -v pacman-conf >/dev/null 2>&1; then
        gaming_ready=false
    else
        gaming_repos=$(pacman-conf --repo-list) || die 'Cannot inspect pacman repositories.'
        if ! printf '%s\n' "$gaming_repos" | grep -qx multilib; then gaming_ready=false; fi
    fi
    if ! "$gaming_ready"; then
        gaming_message='Enable [multilib] and its Include line in /etc/pacman.conf, then manually run sudo pacman -Syu and rerun gaming/steam. The installer never refreshes databases or upgrades the system.'
        if "$dry_run"; then printf 'NOTE: %s\n' "$gaming_message"; else die "$gaming_message"; fi
    elif ! pacman -Si steam >/dev/null 2>&1; then
        gaming_message='Multilib is enabled but Steam is absent from the local sync database. Manually run sudo pacman -Syu, then rerun gaming/steam.'
        if "$dry_run"; then printf 'NOTE: %s\n' "$gaming_message"; else die "$gaming_message"; fi
    fi
    if "$gaming_nvidia"; then
        if "$dry_run"; then
            printf 'NOTE: nvidia requires an already configured, compatible NVIDIA kernel driver and nvidia-utils. Hybrid offload remains a host-specific setup.\n'
        else
            pacman -Q nvidia-utils >/dev/null 2>&1 || die 'Configure the NVIDIA kernel driver and nvidia-utils first; gaming only adds matching userspace libraries.'
        fi
    fi
    if ! "$dry_run"; then
        # All names come from the fixed package lists above.
        # shellcheck disable=SC2086
        pacman -Si $gaming_packages >/dev/null 2>&1 || die 'Selected gaming packages are unavailable in local sync databases. Review repositories and perform a manual full update.'
    fi
}
gaming_install() {
    # shellcheck disable=SC2086
    packages $gaming_packages
    printf '  Start Steam as your normal user; select Proton in Steam Compatibility settings as needed.\n'
    printf '  Optional launch options: gamemoderun %%command%%; mangohud %%command%% (only for installed extras).\n'
}

apply_module() {
    case $1 in
        desktop|steam) : ;;
        gaming) gaming_install ;;
        base)
            packages base-devel bc firefox man-db man-pages pacman-contrib playerctl powertop unzip words wget libnotify xdg-utils openssh
            run sudo systemctl enable --now paccache.timer
            printf '  fstrim.timer: enable manually after checking storage/discard support. Locale left unchanged.\n'
            ;;
        git) packages git lazygit ;;
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
            system_file "${KEYD_CONFIG}" /etc/keyd/default.conf
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
