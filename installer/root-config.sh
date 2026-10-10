#!/bin/sh
# Root-only deployment entrypoint. Functions are also sourced by fixture tests.
set -eu

root_backup() {
    if [ -e "$1" ] || [ -L "$1" ]; then
        mkdir -p "$root_backup_dir$1"
        [ ! -e "$root_backup_dir$1/original" ] && [ ! -L "$root_backup_dir$1/original" ] || return 0
        cp -a -- "$1" "$root_backup_dir$1/original"
    fi
}
root_directory() {
    if [ -L "$1" ] || { [ -e "$1" ] && [ ! -d "$1" ]; }; then
        printf 'Refusing unexpected root directory/symlink: %s\n' "$1" >&2
        exit 1
    fi
    mkdir -p -- "$1"
}
root_link() {
    if [ -L "$2" ] && [ "$(readlink -- "$2")" = "$1" ]; then return; fi
    root_backup "$2"
    if [ -e "$2" ] || [ -L "$2" ]; then
        # Save conflicting directories without following symlinks into user data.
        mv -T -- "$2" "$root_backup_dir$2/displaced"
    fi
    ln -sT -- "$1" "$2"
}
root_runtime_directory() {
    if [ -L "$1" ] || { [ -e "$1" ] && [ ! -d "$1" ]; }; then
        root_backup "$1"
        mv -T -- "$1" "$root_backup_dir$1/displaced"
    fi
    mkdir -p -- "$1"
}
deploy_root() {
    # Validate all parent paths before creating anything or changing passwd.
    for directory in "$root_home" "$root_home/.config" "$root_home/.local" "$root_home/.local/bin" "$root_home/.local/state" "$root_home/.cache" "$root_home/.local/share"; do
        if [ -L "$directory" ] || { [ -e "$directory" ] && [ ! -d "$directory" ]; }; then
            printf 'Refusing unexpected root parent: %s\n' "$directory" >&2; exit 1
        fi
    done
    mkdir -p "$root_backup_dir"
    chmod 700 "$root_backup_dir"
    root_directory "$root_home"
    chmod 700 "$root_home"
    for directory in .config .local/bin .local/state .cache .local/share; do root_directory "$root_home/$directory"; done
    for directory in .local/state/zsh .local/state/nvim .cache/zsh .cache/nvim .local/share/nvim; do root_runtime_directory "$root_home/$directory"; done
    root_link "$root_repo/config/zsh" "$root_home/.config/zsh"
    root_link "$root_repo/starship.toml" "$root_home/.config/starship.toml"
    root_link "$root_nvim" "$root_home/.config/nvim"
    root_link "$root_repo/config/bin/fetch" "$root_home/.local/bin/fetch"
    # ZDOTDIR redirects startup away from ~/.zshenv, but preserve any existing one.
    # Only config directories are linked; runtime directories remain account-local.
    if [ "$old_root_home" != "$root_home" ] || [ "$old_root_shell" != /usr/bin/zsh ]; then
        root_backup "$passwd_file"
        # Deliberately no -m: never move or chown the normal user's home.
        usermod -d "$root_home" -s /usr/bin/zsh root
    fi
}

if [ "${1:-}" = --library ]; then return 0; fi
[ "$(id -u)" -eq 0 ] || { printf 'root-config helper needs sudo\n' >&2; exit 1; }
root_repo=$1
root_nvim=$2
root_backup_dir=$3
root_home=/root
passwd_file=/etc/passwd
[ -f "$root_repo/config/zsh/.zshenv" ] && [ -f "$root_nvim/init.lua" ] || { printf 'Missing shared config sources\n' >&2; exit 1; }
root_record=$(getent passwd root)
old_root_home=$(printf '%s\n' "$root_record" | cut -d: -f6)
old_root_shell=$(printf '%s\n' "$root_record" | cut -d: -f7)
deploy_root
