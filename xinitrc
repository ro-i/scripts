#!/bin/sh

. /etc/X11/xinit/xinitrc-common

xdg-user-dirs-update

# cf. https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_DIRS="/usr/local/share/:/usr/share/"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_CACHE_HOME="$HOME/.cache"

# export downloads directory for firejail
export DOWNLOADS="$HOME/Downloads"

# GUI
export GTK_CSD=0
export GTK_OVERLAY_SCROLLING=0
export QT_QPA_PLATFORMTHEME=qt5ct

xsetroot -cursor_name left_ptr
xset r rate 150 30
/opt/scripts/settings "dp" # dp/internal

# use environment variable from /etc/X11/xinit/xinitrc-common
eval $($SSH_AGENT -s)

picom --experimental-backends &

exec /usr/bin/i3
