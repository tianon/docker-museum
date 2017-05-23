#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# avoid "1.24 (downgraded from 1.25)"
export DOCKER_HOST='unix:///LOL/BOGUS'

api_version() {
	local apiVersion="$("$1" version -f '{{.Client.APIVersion}}' 2>/dev/null || true)"
	if [ -z "$apiVersion" ]; then
		apiVersion="$("$1" version 2>/dev/null | awk -F ': +' '$1 ~ / *API version */ { print $2; exit }')"
	fi
	echo "$apiVersion"
}

for dockerBin; do
	dockerBin="$(readlink -f "$dockerBin")"
	if [ "$(dirname "$dockerBin")" != "$(dirname "$dir")" ]; then
		echo >&2 "error: $dockerBin is not in $(dirname "$dir"); ignoring"
		continue
	fi
	sourceBin="../$(basename "$dockerBin")"
	apiVersion="$(api_version "$dockerBin")"
	if [ -z "$apiVersion" ]; then
		echo >&2 "info: $sourceBin returned no APIVersion; ignoring"
		continue
	fi
	targetBin="$dir/docker-$apiVersion"
	if [ -e "$targetBin" ]; then
		: #echo >&2 "info: $(basename "$targetBin") already exists; ignoring $sourceBin"
		: #continue
	fi
	ln -svfT "$sourceBin" "$targetBin"
done
