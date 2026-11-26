#!/bin/sh
# Open a terminal as a new tab in the focused window's group.
# If the focused window isn't grouped yet, group it first.
if hyprctl activewindow -j | grep -q '"grouped": \[\]'; then
    hyprctl dispatch togglegroup >/dev/null
fi
exec alacritty
