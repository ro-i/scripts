#!/bin/bash
# See LICENSE file for copyright and license details.


############
## config ##
############

notes_root="${HOME}/Documents/notes"


###############
## functions ##
###############

die () {
	printf '%s\n' "$0 - error - $1"
}

dmenu_cmd () {
	dmenu -fn DejaVuSansMono-12 -i -l 25  -nb '#162f54' -nf '#e2e2e2' -sb '#6574ff' -sf '#ffffff'
}

editor () {
	gnome-terminal -- nvim "$@"
}

get_dirs () {
	find . -maxdepth 1 -type d ! -path . -printf '→ %P\n' | sort
}

get_files () {
	find . -maxdepth 1 -type f -printf '%T@ %TF   %P\n' | sort -rn | cut -d' ' -f1 --complement
}

list_contains () {
	local value=$1
	local list=$2

	local IFS=$'\n'

	for e in $list; do
		[[ $e == "$value" ]] && return 0
	done

	return 1
}

##########
## code ##
##########

if ! [[ -d $notes_root ]]; then
	if [[ -e $notes_root ]]; then
		die "${notes_root} already exists, but is not a directory"
	fi
	mkdir -m 0700 "$notes_root"
fi

cd "$notes_root" || die "Could not switch to ${notes_root}."

regex_cmd='^\/([^ ]+)\ *(.+)?'
regex_dir='^→ (.+)'
regex_note='^[^ ]+\ +(.+)'

while true; do
	unset cmd cmd_args infix note prefix

	files_l=$(get_files)
	dirs_l=$(get_dirs)

	[[ $PWD != "$notes_root" ]] && prefix="←\n"
	[[ -n $dirs_l ]] && infix="\n"

	input=$(printf "${prefix}%s${infix}%s" "$files_l" "$dirs_l" | dmenu_cmd)
	[[ -z $input ]] && exit 0

	if [[ $input == '←' && $PWD != "$notes_root" ]]; then
		cd ..
	elif [[ $input =~ $regex_dir ]]; then
		cd "${BASH_REMATCH[1]}" || die "Could not switch to ${BASH_REMATCH[1]}."
	elif [[ $input =~ $regex_cmd ]]; then
		cmd=${BASH_REMATCH[1]}
		cmd_args=${BASH_REMATCH[2]}
		input=$(printf '%s\n' "Execute cmd: '${cmd}', args: '${cmd_args}'" | dmenu_cmd)
		if [[ -n $input ]]; then
			input=$(eval "$cmd $cmd_args 2>&1")
			[[ $? -ne 0 ]] && printf '%s\n' "$input" | dmenu_cmd > /dev/null
		fi
	else
		break
	fi
done

if list_contains "$input" "$files_l"; then
	if [[ $input =~ $regex_note ]]; then
		note=${BASH_REMATCH[1]}
	else
		die "Something seems to be wrong with the input parsing."
	fi
else
	note=$input
fi

editor "$note"
