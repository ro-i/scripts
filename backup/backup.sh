#!/bin/bash

die () {
	[[ -n $* ]] && echo "ERROR: $*"
	exit 1
}

sync() {
	[[ -d $1 ]] || die "$1 does not exist or is not a directory"
	[[ -d $2 ]] || die "$2 does not exist or is not a directory"
	[[ -r $3 ]] || die "$3 does not exist or is not readable"

	if [[ -n $dry_run ]]; then
		opts=("--dry-run" "-v")
	else
		opts=("--info=PROGRESS2")
	fi
	rsync -aAHX --delete --filter="merge $3" "${opts[@]}" "$1" "$2"
}

usage () {
	echo -e "\
Usage: $0 [-d] [-f <file>] <source directory> <target directory>

Backup files from source directory to target directory.
REMEMBER: trailing slash makes a difference!

Arguments:
  -h           show this help
  -d           dry run
  -f <file>    use given rsync filter file instead of 'backup.filter'"
}


while getopts dhf: opt; do
	case "$opt" in
		d) dry_run=1;;
		h) usage; exit 0;;
		f) filter=$OPTARG;;
		\?) usage; die;;
	esac
done

filter=${filter:-"backup.filter"}
source=${!OPTIND}
OPTIND=$((OPTIND+1))
target=${!OPTIND}

# check arguments
[[ -z $source ]] && { usage; die; }
[[ -z $target ]] && { usage; die; }

echo "Will do backup from $source to $target"

while [[ ! $key =~ (^y$|^n$) ]]; do
	read -rp "Do you want to proceed? (TRAILING SLASH?) [y/n] " key
done
case $key in "n") exit;; esac

# execute syncs
echo "Backup is running ..."
sync "$source" "$target" "$filter" || die "backup failed"

dnf repoquery --installed > "$target/pkg_all" || die "listing all installed packages failed"
dnf repoquery --userinstalled > "$target/pkg_manual" || die "listing all userinstalled packages failed"

echo "Finished."
