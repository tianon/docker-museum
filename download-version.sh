#!/bin/bash
set -e

if ! [ "$#" -gt 0 ]; then
	echo >&2 "usage: $0 version [version ...]"
	echo >&2 "   ie: $0 17.03.1-ce"
	echo >&2 "       $0 17.04.0-ce 17.05.0-ce"
	exit 1
fi

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

urlBase='https://download.docker.com/linux/static'
declare -A linuxArchDirs=(
	[x86_64]=''
	[armhf]='linux/armhf'
	[s390x]='linux/s390x'
)

download() {
	local version="$1"; shift
	local arch="$1"; shift

	local channel='edge'
	if [[ "$version" == *rc* ]]; then
		channel='test'
	elif minorVersion="${version##*.}" && minorVersion="${minorVersion%-ce}" && [ "$(( minorVersion % 3 ))" = '0' ]; then
		channel='stable'
	fi

	pwd
	targetBin="docker-$version"
	#target="$targetBin"
	target="$targetBin.tgz"
	for url in \
		"$urlBase/$channel/$arch/$targetBin-$arch.tgz" \
		"$urlBase/$channel/$arch/$targetBin.tgz" \
	; do
		if ( set -x; curl -fSL'#' "$url" -o "$target" ); then
			break
		fi
	done
	if [ -s "$target" ]; then
		case "$target" in
			*.tgz)
				( set -x; tar -xOf "$target" docker/docker > "$targetBin" )
				;;
		esac
		if [ -f "$targetBin" ]; then
			( set -x; chmod +x "$targetBin" )
		fi
	else
		echo "awww, no Docker $version at $urlBase for $arch"
		( set -x; rm -f "$target" )
	fi
}

while [ "$#" -gt 0 ]; do
	version="$1"; shift

	for arch in "${!linuxArchDirs[@]}"; do
		archDir="${linuxArchDirs[$arch]}"
		(
			if [ -n "$archDir" ]; then
				mkdir -p "$archDir"
				cd "$archDir"
			fi
			download "$version" "$arch"
		)
	done

	case "$version" in
		#*rc*) ;;
		*) ./api-version/symlink.sh "./docker-$version" ;;
	esac
done
