#!/bin/sh

args="$@"

o=$(echo 'poweroff\nreboot\nhibernate\nhybrid-sleep\nsuspend' | dmenu $args -i -p "Choose Power State:")

systemctl $o
