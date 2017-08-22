#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

cat <<'EOH'
# To determine the proper value for this, download
# https://download.docker.com/linux/static/CHANNEL/x86_64/docker-VERSION-ce.tgz
# extract "docker", run "./docker -v", which will list the exact build hash needed.

EOH

for d in docker-*; do
	[ -x "$d" ] || continue
	v="$("./$d" -v | awk '{ sub(/-ce/, "", $3); sub(/,$/, ": ", $3); print $3 $5 }')"
	if [[ "$v" == *-dirty ]]; then
		# skip dirty releases :(
		continue
	fi
	echo "$v"
done | sort --version-sort
