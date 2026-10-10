#!/bin/sh
set -eu
choice=$(printf '%s\n' poweroff reboot hibernate hybrid-sleep suspend | dmenu "$@" -i -p 'Choose Power State:') || exit 0
case $choice in poweroff|reboot|hibernate|hybrid-sleep|suspend) exec systemctl "$choice" ;; esac
