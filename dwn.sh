#!/bin/bash
# See LICENSE file for copyright and license details.
set -e

# The youtube-dl binary this script should use.
ydlbin='/usr/bin/youtube-dl'
# The default parameters.
params='--no-playlist'


print_ok () {
	printf '%b\n' '[\e[01;32mOK\e[m]'
}

print_fail () {
	printf '%b\n' '[\e[01;31mFAILED\e[m]'
}

read_prompt_to_var () {
	read -erp "$1" "$2"
}


cd "$HOME"

if [[ -n $1 ]]; then
	case "$1" in
		'debug')
			debug=1
			;;
		*)
			echo "usage: ${0} [debug]"
			exit 1
			;;
	esac
fi

read_prompt_to_var $'\e[01;34mURL to Audio/Video: \e[m' 'url'

printf '\n%s\n\n' 'There are multiple options for the download:'

PS3=$'\n\e[01;34mSelect option (enter the number): \e[m'
options=(
	'Audio+Video, best quality available'
	'Audio+Video, format mp4'
	'Audio, best quality available'
	'Audio, format mp3'
	'Audio, format wav'
	'Quit'
)
select name in "${options[@]}"; do
	case "$name" in
		"${options[0]}")
			break
			;;
		"${options[1]}")
			params+=" -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"
			break
			;;
		"${options[2]}")
			params+=' -x --audio-quality=0'
			break
			;;
		"${options[3]}")
			params+=' -x --audio-format=mp3 --audio-quality=0'
			break
			;;
		"${options[4]}")
			params+=' -x --audio-format=wav --audio-quality=0'
			break
			;;
		"${options[5]}")
			print_ok;
			exit 0
			;;
		*)
			echo 'Input error. Please try again.'
			;;
	esac
done

if [[ -n $debug ]]; then
	"$ydlbin" $params "$url"
	print_ok
	exit 0
else
	output=$("$ydlbin" $params "$url" 2>&1)
fi

if [[ $output =~ ERROR ]]; then
	print_fail
	exit 1
fi

ofile=$(sed -En 's/^\[ffmpeg\] Destination: |^\[ffmpeg\] Merging formats into "([^"]*)"/\1/p' <<< "$output")

if [[ -z $ofile ]]; then
	echo 'Error: maybe the file already exists?'
	print_fail;
	exit 1
fi

while true; do
	read_prompt_to_var $'\e[01;34mEnter the desired file name: \e[m' 'nfile'

	if [[ $nfile =~ / ]]; then
		echo 'The file name must not contain a slash "/".'
	elif [[ -f $nfile ]]; then
		echo 'A file with this name already exists.'
	elif [[ -n $nfile ]]; then
		mv "$ofile" "$nfile"
		break
	fi
done

# Update file modification timestamp.
touch "$nfile"

print_ok
exit 0
