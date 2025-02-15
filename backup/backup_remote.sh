#!/bin/bash

die () {
	[[ -n $* ]] && echo "ERROR: $*"
	exit 1
}

measure () {
	/bin/time -f "Elapsed time: %E" -- "$@" || die "command failed: $*"
}

proceed () {
	while [[ ! $key =~ (^y$|^n$) ]]; do
		read -rp "Do you want to proceed? (TRAILING SLASH?) [y/n] " key
	done
	case $key in "n") exit;; esac
}

read_password () {
	read -rsp "Enter encryption password: " pw
}

common_tar_opts=("-I" "zstd -T0" "-p" "--acls" "--selinux" "--xattrs")
common_ssl_opts=("-aes-256-cbc" "-salt" "-pbkdf2" "-pass" "stdin")
file_list="file_list_to_backup_$(date '+%s')"
[[ -e $file_list ]] && die "$file_list already exists"
file_list_partial="$file_list.partial"
[[ -e $file_list_partial ]] && die "$file_list_partial already exists"
max_tarball_size=4000000000

# args: source filter
get_file_list() {
	local find_opts=() or_op="" line_format='%s %p\0'

	[[ -d $1 ]] || die "$1 does not exist or is not a directory"
	[[ -r $2 ]] || die "$2 does not exist or is not readable"

	find_opts+=('(')
	while read -r exclude; do
		[[ -n $or_op ]] && find_opts+=("$or_op")
		find_opts+=("-path" "$1$exclude")
		or_op="-o"
	done < "$2"
	[[ -n $or_op ]] && find_opts+=("$or_op")
	find_opts+=('(' "-path" "$1.*" "!" "-path" "$1.config" ')' ')' "-prune")

	[[ -n $only_file_list ]] && line_format='%s %p\n'

	echo "Writing file list to $file_list ..."
	measure find "$1" "${find_opts[@]}" -o ! -type d -fprintf "$file_list" "$line_format"
}

# args: tarball file_list target
backup_partial() {
	local pw

	echo "Compressing partial file list to $1 ..."
	measure tar -C / "${common_tar_opts[@]}" -cf "$1" --null -T "$2"

	echo "Encrypting $1 to $1.enc ..."
	measure openssl enc "${common_ssl_opts[@]}" -in "$1" -out "$1.enc" <<< "$pw"

	echo "Copying $1.enc to $3 ..."
	measure rclone copy "$1.enc" "$3"

	rm "$1" "$1.enc"
}

# args: source target tarball
backup() {
	local dur filesize filename size=0 counter=0

	[[ -d $1 ]] || die "$1 does not exist or is not a directory"

	echo "Start compressing in chunks (max $max_tarball_size bytes if possible) ..."
	dur=$(date "+%s")

	# Setting IFS is still necessary (although we set -d for read) to ensure
	# that no whitespace is stripped from the lines.
	while IFS= read -r -d $'\0' line; do
		filesize=${line%% *}
		filename=${line#* }
		# strip leading /
		filename=${filename#/}
		if ((size > 0 && size+filesize > max_tarball_size)); then
			backup_partial "$3.$counter" "$file_list_partial" "$2"
			counter=$((counter+1))
			size=$filesize
			printf '%s\0' "$filename" > "$file_list_partial"
		else
			size=$((size+filesize))
			printf '%s\0' "$filename" >> "$file_list_partial"
		fi
	done < "$file_list"

	[[ -s $file_list_partial ]] && backup_partial "$3.$counter" "$file_list_partial" "$2"
	rm "$file_list" "$file_list_partial"

	dur=$((dur-$(date "+%s")))
	echo "Total elapsed time: $((dur / 3600)):$(((dur % 3600) / 60)):$(((dur % 3600) % 60))"
}

# args: source target tarball
extract() {
	local start_dir dur chunk

	[[ -d $1 ]] || die "$1 does not exist or is not a directory"

	start_dir=${1%%\/*}
	[[ -z $start_dir ]] && start_dir="/"

	echo "Start extracting chunks from $2 to $1 ..."
	dur=$(date "+%s")

	for chunk_enc in rclone lsf "$2" --include "$tarball*"; do
		chunk=${chunk_enc%.enc}
		chunk_enc_file=$(basename "$chunk_enc")

		echo "Copying $chunk_enc to $chunk_enc_file ..."
		measure rclone copy "$chunk_enc" "$chunk_enc_file"

		echo "Decrypting $chunk_enc to $chunk ..."
		measure openssl enc -d "${common_ssl_opts[@]}" -in "$chunk_enc_file" -out "$chunk" <<< "$pw"

		echo "Extracting $chunk to $1 ..."
		measure tar -C "$start_dir" "${common_tar_opts[@]}" -xf "$chunk" "$1"

		rm "$chunk_enc_file" "$chunk"
	done

	dur=$((dur-$(date "+%s")))
	echo "Total elapsed time: $((dur / 3600)):$(((dur % 3600) / 60)):$(((dur % 3600) % 60))"
}

usage () {
	echo -e "\
Usage: $0 [-d] [-f <file>] [-t <file>] [-x] <source directory> <backup destination>

Create an encrypted tarball from source directory and write it to the backup destination.
REMEMBER: trailing slash!
Note: the backup destination is an rclone argument.

Arguments:
  -h           show this help
  -d           generate and output the list of files which would be backup'd
                 (use newlines instead of zero bytes to separate the filenames)
  -f <file>    use given 'find' filter file instead of 'backup_remote.filter'
  -t <file>    use given target tarball name (without extension) instead of 'backup'
  -x           extract files from backup"
}


while getopts dhf:t:x opt; do
	case "$opt" in
		d) only_file_list=1;;
		h) usage; exit 0;;
		f) filter=$OPTARG;;
		t) tarball_name=$OPTARG;;
		x) reverse=1;;
		\?) usage; die;;
	esac
done

filter=${filter:-"backup_remote.filter"}
tarball="${tarball_name:-"backup"}.tar.zst"
source=${!OPTIND}
OPTIND=$((OPTIND+1))
target=${!OPTIND}

# check arguments
[[ -z $source ]] && { usage; die; }
[[ -z $only_file_list && -z $target ]] && { usage; die; }

if [[ -n $only_file_list ]]; then
	get_file_list "$source" "$filter"
elif [[ -n $reverse ]]; then
	echo "Will do extraction from $target$tarball.enc{0..} to $source"
	proceed

	read_password
	extract "$source" "$target" "$tarball" || die "extraction failed"
else
	echo "Will do backup from $source to $target$tarball.enc{0..}"
	proceed

	get_file_list "$source" "$filter"
	read_password
	backup "$source" "$target" "$tarball" || die "backup failed"
fi

echo "Finished."
