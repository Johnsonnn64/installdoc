#!/bin/sh
# shellcheck disable=SC2016
# Replace only the inspected legacy global settings; preserve unrelated lines.
set -eu
mode=$1
repo=$2
backup_dir=$3
zsh_dir=${4:-/etc/zsh}

filter() {
    awk -v kind="$1" '
    /^[[:space:]]*# installdoc shared startup/ { next }
    kind == "env" && /^[[:space:]]*export ZDOTDIR=/ {
        # Known legacy absolute path or the managed account-relative setting.
        if ($0 ~ /\.config\/zsh\/?[\047\042]?[[:space:]]*$/) next
        print "Unrecognized global ZDOTDIR assignment: " $0 > "/dev/stderr"
        exit 1
    }
    kind == "profile" && /\.zprofile/ && $0 !~ /^[[:space:]]*#/ {
        if ($0 ~ /^[[:space:]]*(source|\.)[[:space:]]+[\047\042]?(\$HOME|\/home\/[^\/]+)\/\.config\/zsh\/\.zprofile[\047\042]?[[:space:]]*$/) next
        print "Unrecognized global profile sourcing: " $0 > "/dev/stderr"
        exit 1
    }
    { print }
    ' "$2"
}

for kind in env profile; do
    case $kind in env) file=$zsh_dir/zshenv ;; profile) file=$zsh_dir/zprofile ;; esac
    if [ -f "$file" ]; then filter "$kind" "$file" >/dev/null; fi
done
[ "$mode" != --check ] || exit 0
[ "$mode" = --apply ] || { printf 'Expected --check or --apply\n' >&2; exit 1; }

stage=$(mktemp -d /tmp/installdoc-zsh.XXXXXXXX)
trap 'rm -rf -- "$stage"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
for kind in env profile; do
    case $kind in env) file=$zsh_dir/zshenv ;; profile) file=$zsh_dir/zprofile ;; esac
    if [ -f "$file" ]; then filter "$kind" "$file" > "$stage/zsh$kind";
    else : > "$stage/zsh$kind"; fi
    if [ "$kind" = env ]; then
        printf '%s\n' '# installdoc shared startup' 'export ZDOTDIR="$HOME/.config/zsh"' >> "$stage/zshenv"
    elif ! grep -q '/etc/profile' "$stage/zshprofile"; then
        cat "$repo/system/zprofile" >> "$stage/zshprofile"
    fi
done
for kind in env profile; do
    case $kind in env) file=$zsh_dir/zshenv ;; profile) file=$zsh_dir/zprofile ;; esac
    if [ ! -L "$file" ] && [ -f "$file" ] && cmp -s "$stage/zsh$kind" "$file"; then continue; fi
    if [ -e "$file" ] || [ -L "$file" ]; then
        mkdir -p "$backup_dir$file"
        cp -a -- "$file" "$backup_dir$file/original"
    fi
    mkdir -p "$zsh_dir"
    install -m 644 "$stage/zsh$kind" "$zsh_dir/.installdoc-$kind-$$"
    mv -fT "$zsh_dir/.installdoc-$kind-$$" "$file"
done
