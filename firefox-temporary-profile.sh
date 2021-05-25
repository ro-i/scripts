#!/bin/sh
# See LICENSE file for copyright and license details.

# Start Firefox with a temporary profile.
#
# cf. https://qasimk.io/2019/temporary-firefox-profile/
# or https://cat-in-136.github.io/2012/12/tip-how-to-run-new-firefox-instance-w.html
# 
# Temporary profile should be in memory, so put it into /tmp.
# As "firejail firefox --profile [...]" would build a new /tmp without our
# newly generated profile directory, start an appropriately confined shell
# and execute firefox in this shell.

# firefox or firefox-esr
ff="firefox"

firejail --profile="$ff" -- sh -c '
set -eu

profiledir=$(mktemp -d /tmp/tmp-ff-profile.XXXXXXXXXX.d)
'"$ff"' --profile "$profiledir" --no-remote
rm -rf "$profiledir"
'
