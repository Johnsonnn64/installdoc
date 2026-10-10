#!/bin/sh
# Build a snapshot as the user; only copy final artifacts with sudo.
set -eu
source_dir=$1
kind=$2
root=$3
backup=$4
check_only=${5:-}
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/installdoc-build.XXXXXXXX")
trap 'rm -rf -- "$build_dir"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
cp -a "$source_dir/." "$build_dir/"
cd "$build_dir"
if [ "$kind" = dwm ]; then
    # Retire mount bindings only in the build snapshot, preserving source work.
    for config in config.h config.def.h; do
        [ -f "$config" ] || continue
        sed '/DMENUS(mountcmd,/d; /DMENUS(umountcmd,/d; /\.v = mountcmd/d; /\.v = umountcmd/d' "$config" > "$config.new"
        mv "$config.new" "$config"
    done
fi
make clean
make PREFIX=/usr/local
make PREFIX=/usr/local DESTDIR="$build_dir/stage" install
if [ "$check_only" = --check ]; then
    printf 'Build and staged install passed: %s\n' "$kind"
    exit 0
fi
# Reuse backup/privileged-file logic without invoking an installer module.
. "$root/installer/common.sh"
trap 'result=$?; rm -rf -- "$build_dir"; exit "$result"' 0
dry_run=false
module=$kind
BACKUP=$backup
for file in "$build_dir"/stage/usr/local/bin/*; do
    system_file "$file" "/usr/local/bin/${file##*/}" 755
done
for file in "$build_dir"/stage/usr/local/share/man/man1/*; do
    system_file "$file" "/usr/local/share/man/man1/${file##*/}" 644
done
