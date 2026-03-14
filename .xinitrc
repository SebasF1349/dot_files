#!/bin/bash

# Ensure DBus is running correctly
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

# Set XDG variables for consistency
export XDG_CURRENT_DESKTOP=i3
export XDG_SESSION_TYPE=x11

# Load resources and keymaps
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources
setxkbmap -layout us -variant altgr-intl -option "lvl3:rctrl"

# Start i3
exec i3
