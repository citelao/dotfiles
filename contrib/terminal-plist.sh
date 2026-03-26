#!/bin/bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tracked_plist="$repo_root/dotfiles/private_Library/private_Preferences/private_com.apple.Terminal.plist"
live_plist="$HOME/Library/Preferences/com.apple.Terminal.plist"

usage() {
	cat <<'EOF'
Usage: contrib/terminal-plist.sh <command>

Commands:
  export  Convert the live Terminal plist to XML and write it into the repo.
  import  Import the tracked XML plist into the Terminal defaults domain.
EOF
}

if [[ $# -ne 1 ]]; then
	usage
	exit 1
fi

case "$1" in
	export)
		/usr/bin/plutil -convert xml1 -o "$tracked_plist" "$live_plist"
		;;
	import)
		tmpdir=$(mktemp -d)
		trap 'rm -rf "$tmpdir"' EXIT
		/usr/bin/plutil -convert binary1 -o "$tmpdir/com.apple.Terminal.plist" "$tracked_plist"
		/usr/bin/defaults import com.apple.Terminal "$tmpdir/com.apple.Terminal.plist"
		;;
	*)
		usage
		exit 1
		;;
esac