#!/bin/bash
# See LICENSE file for copyright and license details.

dmenu_cmd () {
	dmenu -fn DejaVuSansMono-12 -i -l 25 -nb '#162f54' -nf '#e2e2e2' -sb '#6574ff' -sf '#ffffff'
}

update_config () {
	local size=$1
	local dpi=$2
	local text_scale=$3

	xrandr --dpi "$dpi" --fb "$size"
	sed -i '/^Xft.dpi:.*/d' ~/.Xresources ~/.Xdefaults
	echo "Xft.dpi: ${dpi}" >> ~/.Xresources
	echo "Xft.dpi: ${dpi}" >> ~/.Xdefaults
	xrdb -load ~/.Xresources
	gsettings set org.gnome.desktop.interface text-scaling-factor "$text_scale"

	/usr/bin/feh --no-fehbg --bg-fill /home/robert/Pictures/computer/fly_large.png
}


input=(
	"Monitor - Change from internal output to DP"
	"Monitor - Clone internal output to HDMI"
	"Monitor - Change from DP to internal output"
	"Monitor - Change from HDMI to internal output"
	"DPMS - Disable"
	"DPMS - Enable"
)

dp_output="DP-1"
hdmi_output="HDMI-1"
internal_output="eDP-1"

dp_dpi="96"
internal_dpi="96" #"118"

dp_size="1920x1080"
internal_size="1920x1080"

dp_text_scale="1.0"
internal_text_scale="1.0"


case "$1" in
	"dp")
		choice="${input[0]}"
		;;
	"internal")
		choice="${input[2]}"
		;;
	*)
		choice="$(printf '%s\n' "${input[@]}" | dmenu_cmd)"
		;;
esac
[[ -z $choice ]] && exit 1

case $choice in
	"${input[0]}")
		xrandr --output "$internal_output" --off --output "$dp_output" --auto
		update_config "$dp_size" "$dp_dpi" "$dp_text_scale"
		;;
	"${input[1]}")
		xrandr --output "$hdmi_output" --auto --same-as "$internal_output"
		;;
	"${input[2]}")
		xrandr --output "$internal_output" --auto --output "$dp_output" --off
		update_config "$internal_size" "$internal_dpi" "$internal_text_scale"
		;;
	"${input[3]}")
		xrandr --output "$internal_output" --auto --output "$hdmi_output" --off
		;;
	"${input[4]}")
		xset s off -dpms
		;;
	"${input[5]}")
		xset s default +dpms
		;;
esac

xset r rate 150 30

exit 0
