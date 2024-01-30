#!/bin/fish

# source for the terminal
xrdb -merge $HOME/.xres

# font
xset fp+ $HOME/.fonts
xset fp rehash

# set keyboard layout to us
setxkbmap us

# screen resolution
xrandr --output Virtual-1 --mode 1920x1080 &
xset led 3 &
randomWallpaper &
picom &
slstatus &
dunst &
flameshot &

#welcome &

# Start your wm!
exec pdwm
