#!/bin/fish

# source for the terminal
xrdb -merge $HOME/.xres

# font
xset fp+ $HOME/.fonts
xset fp rehash

# set keyboard layout to us
setxkbmap us

# screen resolution
xrandr --output HDMI-1 --mode 1920x1080 &
xrandr --output eDP-1 --off &
nm-applet &
xset led 3 &
randomWallpaper &
picom --animations -b &
slstatus &
dunst &
flameshot &
#welcome &
updatedb &
# Start your wm!
# #exec pdwm
