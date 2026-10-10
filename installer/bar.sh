#!/bin/sh
# The source stays in jondwm. Adapt its legacy path in a generated runtime copy.
set -eu
source_dir=$1
state=$2
mkdir -p "$state"
# Expand HOME when the generated bar runs, not while installing.
# shellcheck disable=SC2016
sed -e 's|~/workspace/suckless/jondwm/bar/catppuccin|"$HOME/workspace/git/jondwm/bar/catppuccin"|' \
    -e 's|read=~/.cache/batt|read=${XDG_CACHE_HOME:-$HOME/.cache}/batt|' \
    -e 's#reset=$(cat "$read")#reset=$(cat "$read" 2>/dev/null) || reset=1#' \
    -e 's|ac_state="$(cat /sys/class/power_supply/AC/online)"|ac_state="$(cat /sys/class/power_supply/AC/online 2>/dev/null)"; ac_state=${ac_state:-0}|' \
    -e 's/\^\$red\^/\^c$red\^/' \
    -e '/pactl get-sink-volume/s/printf /printf "%s" /' \
    -e '/pactl get-sink-volume/s/)%"/)"/' \
    "$source_dir/bar/bar.sh" > "$state/bar.sh.new"
chmod 755 "$state/bar.sh.new"
mv "$state/bar.sh.new" "$state/bar.sh"
