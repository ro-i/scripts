#!/bin/bash
# See LICENSE file for copyright and license details.

# The terminal emulator to use.
terminal_app='gnome-terminal'

declare -A colors
colors=(
	['default']='#e2e2e2'
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

# Listen on external events triggering item updates.
monitors=(
	'volume_monitor'
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

# Regular update interval in seconds.
update_interval_default=10
update_interval_short=5

# Some regexes.
regex_name='[^\\]"name":[[:space:]]*"(([^"]|\\")*[^\\])"'
regex_button='[^\\]"button":[[:space:]]*([[:digit:]]+)'

# Main input pipe. DO NOT CHANGE!
fd_input_pipe=3


## Utility functions
## -----------------


check_dependencies () {
	dependencies=(
		"$terminal_app" 'amixer' 'cal' 'cat' 'date' 'flock' 'less'
		'pavucontrol' 'printf' 'stdbuf' 'tty'
	)
	for dep in "${dependencies[@]}"; do
		type "$dep" > /dev/null 2>&1 && continue
		printf '%s\n%s\n' "Error: unmet dependency: $dep" \
			"My dependencies are: ${dependencies[*]}"
		exit 1
	done
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

err () {
	to_json 'err' 'error' "${colors['red']}"
}

# Executes an external command if it is available.
# Takes the name of the command as first parameter and its arguments
# as string as second parameter.
exec_cmd () {
	local cmd=$1
	local args=$2
	local background=$3

	if ! type "$cmd" > /dev/null 2>&1; then
		return
	fi

	if [[ -n $background ]] && $background; then
		i3-msg -q exec "${cmd} ${args}"
	else
		eval "${cmd} ${args}"
	fi
}

# Takes a string and a regex with a capture and returns the captured
# string, if it has been found.
get_regex_match () {
	[[ $1 =~ $2 ]]
	printf '%s' "${BASH_REMATCH[1]}"
}

# Redirect input to $fd_input_pipe, using locking.
input_redirector () {
	# Get the pid of the actual bash process, not the subshell.
	local fd="/proc/$$/fd/${fd_input_pipe}"

	while read -d '}' -r input; do
		# Append the delimiter again.
		input+='}'
		# Redirect the input to the actual input pipe.
		flock "$fd" -c "printf '%s\n' '${input}' > '${fd}'"
	done
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
	local delim result

	for item in "${line_items[@]}"; do
		result+="${delim}${output_items[$item]}"
		[[ -z $delim ]] && delim=', '
	done

	printf '[%s],\n' "$result"
}

# A separate reader for stdin.
# Avoids race conditions by using locking on the actual input pipe
# which is also used by the monitors.
start_input_listener () {
	local fd=0

	if tty -s; then
		# Use a new file descriptor to not mess up with
		# terminal stdin/stdout
		exec 4<> <(:)
		exec 0>>/proc/self/fd/4
		fd=4
	fi
	(input_redirector < /proc/$$/fd/$fd) &
}

# Start all monitors in background and establish the input pipe
# collecting their ouput.
start_monitors () {
	for monitor in "${monitors[@]}"; do
		({ "$monitor" | input_redirector; }) &
	done
}

# Gets the name of a lineitem, its new value and optionally also its
# new color and returns a corresponding json object.
to_json () {
	local name=$1
	local full_text=$2
	local color=$3

	[[ -z $color ]] && color=${colors['default']}

	printf '{ "name": "%s", "full_text": "%s", "color": "%s", "separator_block_width": 29 }'\
		"$name" "$full_text" "$color"
}


## Item update functions
## ---------------------


backlight_f () {
	local button=$1
	local brightness percentage

	brightness=$(< '/sys/class/backlight/intel_backlight/brightness')
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
			percentage=$((brightness / 1200))
			to_json 'backlight_f' "☀ ${percentage}%"
			;;
	esac
}

battery_f () {
	local cap state suffix

	state=$(< '/sys/class/power_supply/BAT0/status')
	cap=$(< '/sys/class/power_supply/BAT0/capacity')

	[[ -z $state || -z $cap ]] && return

	case $state in
		'Full')
			suffix='% (=)'
			;;
		'Charging')
			suffix='% (+)'
			;;
		'Discharging')
			suffix='% (-)'
			;;
		'Unknown')
			suffix='% (~)'
			;;
		*)
			suffix='% (err)'
			;;
	esac

	to_json 'battery_f' "${cap}${suffix}"
}

ethernet_f () {
	local interface='eno2'
	local result state

	state=$(< "/sys/class/net/${interface}/operstate")
	[[ -z $state ]] && return

	case $state in
		'down')
			result='E'
			;;
		'up')
			speed=$(< "/sys/class/net/${interface}/speed")
			[[ -z $speed ]] && return
			result="E (${speed} MBit/s)"
			;;
		*)
			result='error'
			;;
	esac

	to_json 'ethernet_f' "$result"
}

time_f () {
	local button=$1

	case $button in
		3)
			exec_cmd "$terminal_app" '-- bash -c "cal -wy | less"' true
			;;
		*)
			to_json 'time_f' "$(date +'%H:%M - %d.%m')"
			;;
	esac
}

volume_intern () {
	local button=$1
	local caller=$2
	local device_alsa=$3
	local device_character=$4
	local device_character_muted=$5
	local output result state vol

	case $button in
		2)
			# middle click to open pavucontrol
			exec_cmd 'pavucontrol' '' true
			return
			;;
		3)
			# right klick to toggle mute/unmute
			output=$(exec_cmd 'amixer' "-D pulse set ${device_alsa} toggle")
			;;
		4)
			# scroll up, increase
			output=$(exec_cmd 'amixer' "-D pulse set ${device_alsa} '2%+'")
			;;
		5)
			# scroll down, decrease
			output=$(exec_cmd 'amixer' "-D pulse set ${device_alsa} '2%-'")
			;;
		*)
			output=$(exec_cmd 'amixer' "-D pulse get ${device_alsa}")
			;;
	esac

	[[ -z $output ]] && { err; return; }

	vol=$(get_regex_match "$output" '([[:digit:]]+%)')
	state=$(get_regex_match "$output" '(\[on\]|\[off\])')

	[[ -z $vol || -z $state ]] && return

	case $state in
		'[off]')
			result="${device_character_muted}"
			;;
		*)
			result="${device_character} ${vol}"
			;;
	esac

	to_json "$caller" "$result"
}

volume_f () {
	local button=$1

	volume_intern "$button" 'volume_f' 'Master' '♪' ''
}

volume_mic_f () {
	local button=$1

	volume_intern "$button" 'volume_mic_f' 'Capture' '' ''
}

wifi_f () {
	local button=$1
	local interface='wlo1'
	local dbm operstate result wifi wireless

	operstate=$(< "/sys/class/net/${interface}/operstate")
	[[ -z $operstate ]] && return

	if [[ $operstate == 'down' ]]; then
		to_json 'wifi_f' 'W down'
	fi

	wireless=$(< '/proc/net/wireless')
	[[ -z $wireless ]] && return

	dbm=$(printf '%s' "$wireless" | \
		sed -nE '/^\s*'"${interface}"'/ { s/[^-]*-([0-9]*).*/\1/p;q }')
	[[ -z $dbm ]] && return

	if ((dbm > 93)); then
		result='0%'
	elif ((dbm < 20)); then
		result='100%'
	else
		wifi=$((100 - ((dbm - 20)**2) / 53))
		result="${wifi}%"
	fi

	to_json 'wifi_f' "$result"
}


## Monitor functions
## -----------------


# Do not update the volume using a fixed interval, but monitor volume
# changes (on all cards).
volume_monitor () {
	while read -r line; do
		if [[ "$line" == *'Capture'* ]]; then
			name='volume_mic_f'
		elif [[ "$line" == *'Master Playback'* ]]; then
			name='volume_f'
		else
			continue
		fi
		printf '%s' "{\"name\": \"${name}\", \"button\": 1}"
	done < <(stdbuf --output=L alsactl monitor pulse)
}


## Main part
## ---------


# Check for dependencies.
check_dependencies

# Establish main pipe using fd_input_pipe.
exec 3<> <(:)

start_input_listener
start_monitors

# Print header and start infinite array.
# - cf. https://i3wm.org/docs/i3bar-protocol.html
printf '%s\n%s\n' '{ "version": 1, "click_events": true }' '['

# Initialize output_items and print first line.
do_update "${line_items[@]}"
print_line

update_interval=$update_interval_default
# Initialize time counter.
last_time=$EPOCHSECONDS

while true; do
	# Wait for input until we need to update.
	# Read until we encounter the end of the json array.
	if ! read -d '}' -r -t $update_interval -u 3 input; then
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
