#!/bin/bash
set -eo pipefail

plainDocker=/usr/bin/docker

docker_version() {
	local defaultFormatString='{{.Server.APIVersion}}/{{.Server.Version}}'
	local formatString="${1:-$defaultFormatString}"
	"$plainDocker" version -f "$formatString" 2>/dev/null | tr -d '\r\n'
}

version=
for dockerApiVersion in 1.22 1.18 1.16 1.12; do
	if ! thisVersion="$(DOCKER_API_VERSION="$dockerApiVersion" docker_version)"; then
		continue
	fi
	version="$thisVersion"
	break
done

check_docker() {
	[ -x "$1" ] || command -v "$1" &> /dev/null || return 1
	"$1" version &> /dev/null || return 1
	return 0
}

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

dockers=()
if [ "$version" ]; then
	apiVersion="${version%%/*}"
	version="${version#$apiVersion/}"
	for docker in "$dir/docker-${version%.*}"*; do
		# add in descending order so higher versions are preferred
		dockers=( "$docker" "${dockers[@]}" )
	done
	dockers=(
		"$dir/docker-$version" # prefer exact version match
		"${dockers[@]}" # then prefer close version match (ie, 1.9.0 talking to 1.9.2)
		"$dir/api-version/docker-$apiVersion" # fallback to API version match
	)
else
	echo >&2 "warning: unable to determine Docker version"
fi
dockers+=( "$plainDocker" )

for docker in "${dockers[@]}"; do
	#echo >&2 "trying $docker"
	if check_docker "$docker"; then
		if [ "$1" = '_bin' ]; then
			readlink -f "$docker"
			exit
		fi
		exec "$docker" "$@"
	fi
done

# fall back to just "docker" so we get a decent error message
exec "$plainDocker" "$@"
