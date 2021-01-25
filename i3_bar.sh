#!/bin/bash
# See LICENSE file for copyright and license details.

declare -A colors
colors=(
	['default']='#bdbdbd'
        ['blue']='#46aede'
        ['green']='#94e76b'
        ['red']='#eb4509'
        ['yellow']='#ffac18'
)

# Which lineitems shall be displayed, in which order, and which
# function is responsible for them?
line_items=(
	'time_f'
	'wifi_f'
	'volume_f'
	'volume_mic_f'
	'ethernet_f'
	'backlight_f'
	'battery_f'
)

# Which lineitems shall be updated every 10 seconds?
# (The others are updated only on a click event.)
update_items=(
	'time_f'
	'wifi_f'
	'battery_f'
)

# The output line items (json objects).
declare -A output_items

# Regular update interval in seconds
update_interval_default=10
update_interval_short=5

# Some regexes.
regex_name='[^\\]"name":[[:space:]]*"(([^"]|\\")*[^\\])"'
regex_button='[^\\]"button":[[:space:]]*([[:digit:]]+)'


# Executes an external command if it is available.
# Takes the name of the command as first parameter and its arguments
# as string as second parameter.
exec_cmd () {
	local cmd=$1
	local args=$2

	if ! type "$cmd" > /dev/null 2>&1; then
		return
	fi

	eval "${cmd} ${args}"

	# Detach the process (it may be a daemon process).
	disown -a
}

# Gets the name of a lineitem, its new value and optionally also its
# new color and returns a corresponding json object.
to_json () {
	local name=$1
	local full_text=$2
	local color=$3

	[[ -z $color ]] && color=${colors['default']}

	printf '{ "name": "%s", "full_text": "%s", "color": "%s", "separator_block_width": 19 }'\
		"$name" "$full_text" "$color"
}

backlight_f () {
	local button=$1

	local brightness=$(< '/sys/class/backlight/intel_backlight/brightness')
	[[ -z $brightness ]] && return

	# Note: the brightness values here are very individual!
	case $button in
		4)
			if ((brightness + 1000 <= 120000)); then
				sudo /opt/sandy/setbacklight.sh +1000
			fi
			backlight_f ''
			;;
		5)
			if ((brightness - 1000 >= 0)); then
				sudo /opt/sandy/setbacklight.sh -1000
			fi
			backlight_f ''
			;;
		*)
			local percentage=$((brightness / 1200))
			to_json 'backlight_f' "☀ ${percentage}%"
			;;
	esac
}

battery_f () {
	local color
	local suffix

	local state=$(< '/sys/class/power_supply/BAT0/status')
	local cap=$(< '/sys/class/power_supply/BAT0/capacity')

	[[ -z $state || -z $cap ]] && return

	case $state in
		'Full')
			suffix='% (=)'
			color=${colors['blue']}
			;;
		'Charging')
			suffix='% (+)'
			color=${colors['green']}
			;;
		'Discharging')
			suffix='% (-)'
			color=${colors['red']}
			;;
		'Unknown')
			suffix='% (~)'
			color=${colors['blue']}
			;;
		*)
			suffix='% (err)'
			color=${colors['red']}
			;;
	esac

	to_json 'battery_f' "${cap}${suffix}" "$color"
}

ethernet_f () {
	local color
	local result
	local interface='eno2'

	local state=$(< "/sys/class/net/${interface}/operstate")
	[[ -z $state ]] && return

	case $state in
		'down')
			result='E'
			color=${colors['red']}
			;;
		'up')
			speed=$(< "/sys/class/net/${interface}/speed")
			[[ -z $speed ]] && return
			result="E (${speed} MBit/s)"
			color=${colors['green']}
			;;
		*)
			result='error'
			color=${colors['red']}
			;;
	esac

	to_json 'ethernet_f' "$result" "$color"
}

time_f () {
	local button=$1

	case $button in
		3)
			exec_cmd 'gnome-terminal' '-- bash -c "cal -wy | less" &'
			;;
		*)
			to_json 'time_f' "$(date +'%H:%M - %d.%m')"
			;;
	esac
}

volume_intern () {
	local button=$1
	local caller=$2
	local device=$3
	local device_character=$4
	local output
	local result

	case $button in
		2)
			# middle click to open pavucontrol
			exec_cmd 'pavucontrol' '&'
			return
			;;
		3)
			# right klick to toggle mute/unmute
			output=$(exec_cmd 'amixer' "set ${device} toggle")
			;;
		4)
			# scroll up, increase
			output=$(exec_cmd 'amixer' "set ${device} '2%+'")
			;;
		5)
			# scroll down, decrease
			output=$(exec_cmd 'amixer' "set ${device} '2%-'")
			;;
		*)
			output=$(exec_cmd 'amixer' "get ${device}")
			;;
	esac

	[[ -z $output ]] && return

	local vol=$(get_regex_match "$output" '([[:digit:]]+%)')
	local state=$(get_regex_match "$output" '(\[on\]|\[off\])')

	[[ -z $vol || -z $state ]] && return

	case $state in
		'[off]')
			result="${device_character} ${vol} (-)"
			;;
		*)
			result="${device_character} ${vol}"
			;;
	esac

	to_json "$caller" "$result"
}

volume_f () {
	local button=$1

	volume_intern "$button" 'volume_f' 'Master' '♪'
}

volume_mic_f () {
	local button=$1

	volume_intern "$button" 'volume_mic_f' 'Capture' '#'
}

wifi_f () {
	local button=$1
	local interface='wlo1'
	local result

	local operstate=$(< "/sys/class/net/${interface}/operstate")
	[[ -z $operstate ]] && return

	if [[ $operstate == 'down' ]]; then
		to_json 'wifi_f' 'W down' "${colors['red']}"
	fi

	local wireless=$(< '/proc/net/wireless')
	[[ -z $wireless ]] && return

	local dbm=$(printf '%s' "$wireless" | \
		sed -nE '/^\s*'"${interface}"'/ { s/[^-]*-([0-9]*).*/\1/p;q }')
	[[ -z $dbm ]] && return

	if ((dbm > 93)); then
		result='0%'
	elif ((dbm < 20)); then
		result='100%'
	else
		local wifi=$((100 - ((dbm - 20)**2) / 53))
		result="${wifi}%"
	fi

	to_json 'wifi_f' "$result" "${colors['green']}"
}

err () {
	to_json 'err' 'error' "${colors['red']}"
}

# Update all items in the array passed as argument.
do_update () {
	local result

	for func in "$@"; do
		result=$("$func")
		[[ -z $result ]] && result=$(err)

		output_items["$func"]=$result
	done
}

# Takes a string and a regex with a capture and returns the captured
# string, if it has been found.
get_regex_match () {
	[[ $1 =~ $2 ]]
	printf '%s' "${BASH_REMATCH[1]}"
}

# Takes an element and an array and checks if the array contains that
# element.
is_elem_of () {
	local elem=$1
	shift

	for e in "$@"; do
		[[ $e == "$elem" ]] && return 0
	done

	return 1
}

# Print a full status line. Returns an json array of json opdates
# respresenting the line items.
print_line () {
	local result
	local delim

	for item in "${line_items[@]}"; do
		result+="${delim}${output_items[$item]}"
		[[ -z $delim ]] && delim=', '
	done

	printf '[%s],\n' "$result"
}


update_interval=$update_interval_default

# Print header and start infinite array.
# - cf. https://i3wm.org/docs/i3bar-protocol.html
printf '%s\n%s\n' '{ "version": 1, "click_events": true }' '['

# Initialize output_items and print first line.
do_update "${line_items[@]}"
print_line

# Initialize time counter.
last_time=$EPOCHSECONDS

while true; do
	# Wait for input until we need to update.
	# Read until we encounter the end of the json array.
	if ! read -d '}' -r -t $update_interval input; then
		# Prevent infinite loops.
		((last_time == EPOCHSECONDS)) && exit 1
		last_time=$EPOCHSECONDS

		# If there has been no input within the interval time,
		# just run the regular update.
		do_update "${update_items[@]}"
		print_line
		# We may reset the update interval to its default value.
		update_interval=$update_interval_default
		continue
	fi
	[[ -z $input ]] && exit 1

	# Check the lineitem we need to update.
	lineitem=$(get_regex_match "$input" "$regex_name")
	if [[ -z $lineitem ]] || ! is_elem_of "$lineitem" "${line_items[@]}"; then
		continue
	fi

	# As we only update one field, set the update_interval timer
	# to a smaller value.
	update_interval=$update_interval_short

	# Get the button which activated this event.
	button=$(get_regex_match "$input" "$regex_button")
	[[ -z $button ]] && continue

	# Update the field using its function (passing the button as
	# argument).
	output=$("$lineitem" "$button")
	[[ -z $output ]] && continue
	output_items["$lineitem"]=$output

	# Print the full status line.
	print_line
done
