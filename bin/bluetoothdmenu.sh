#!/bin/sh

dmenu_cmd="dmenu $@"

# choose device and action 
action () {
  chosen=$(echo "$devices" | eval $dmenu_cmd -p Devices -l 10) || exit 1
  chact=$(printf "connect\ndisconnect" | eval $dmenu_cmd -p Action) || exit 1
  chnum=$(echo $chosen | awk '{print $2}')
  chname=$(echo $chosen | awk '{print $3}')
  notify-send "$chname" "$(bluetoothctl "$chact" "$chnum" | sed 's/\[.*.\].//')"
}
  
devices=$(bluetoothctl devices)

action
