#!/bin/sh
# Bootstrap yay-bin without leaving build files in an existing checkout.
set -eu
[ "$(id -u)" -ne 0 ] || { printf 'AUR builds cannot run as root.\n' >&2; exit 1; }
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/installdoc-aur.XXXXXXXX")
trap 'rm -rf -- "$build_dir"' 0
trap 'exit 130' INT
trap 'exit 143' TERM
cp -a "$1/." "$build_dir/"
cd "$build_dir"
makepkg -si --needed
