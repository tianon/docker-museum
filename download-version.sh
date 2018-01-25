#!/bin/bash
set -e

if ! [ "$#" -gt 0 ]; then
	echo >&2 "usage: $0 version [version ...]"
	echo >&2 "   ie: $0 17.03.1-ce"
	echo >&2 "       $0 17.04.0-ce 17.05.0-ce"
	exit 1
fi

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

urlBase='https://download.docker.com'
declare -A archDirs=(
	[linux/x86_64]=''

	[linux/aarch64]='linux/arm64'
	[linux/armel]='linux/armv6'
	[linux/armhf]='linux/armhf'
	[linux/ppc64le]='linux/ppc64le'
	[linux/s390x]='linux/s390x'
	[mac/x86_64]='darwin/amd64'
	[win/x86_64]='windows/amd64'
)

download() {
	local version="$1"; shift
	local platform="$1"; shift
	local arch="$1"; shift

	local channel='edge'
	if [[ "$version" == *rc* ]]; then
		channel='test'
	elif minorVersion="${version#*.}" && minorVersion="${minorVersion%%.*}" && minorVersion="${minorVersion#0}" && [ "$(( minorVersion % 3 ))" = '0' ]; then
		channel='stable'
	fi

	pwd
	targetBin="docker-$version"
	case "$platform" in
		win) targetExt='zip' ;;
		*)   targetExt='tgz' ;;
	esac
	target="$targetBin.$targetExt"
	for url in \
		"$urlBase/$platform/static/$channel/$arch/$targetBin.$targetExt" \
		"$urlBase/$platform/static/$channel/$arch/$targetBin-$arch.$targetExt" \
	; do
		if ( set -x; curl -fSL'#' "$url" -o "$target" ); then
			break
		fi
	done
	if [ -s "$target" ]; then
		case "$targetExt" in
			tgz)
				( set -x; tar -xOf "$target" docker/docker > "$targetBin" )
				;;
			zip)
				# TODO unzip
				;;
			*)
				echo >&2 "error: unknown target extension: $targetExt"
				exit 1
				;;
		esac
		if [ -f "$targetBin" ]; then
			( set -x; chmod +x "$targetBin" )
		fi
	else
		echo >&2
		echo >&2 "awww, no Docker $version at $urlBase for $platform on $arch"
		( set -x; rm -f "$target" )
		echo >&2
	fi
}

while [ "$#" -gt 0 ]; do
	version="$1"; shift

	for arch in "${!archDirs[@]}"; do
		archDir="${archDirs[$arch]}"
		platform="${arch%%/*}"
		platformArch="${arch#$platform/}"
		(
			if [ -n "$archDir" ]; then
				mkdir -p "$archDir"
				cd "$archDir"
			fi
			download "$version" "$platform" "$platformArch"
		)
	done

	case "$version" in
		#*rc*) ;;
		*) ./api-version/symlink.sh "./docker-$version" ;;
	esac
done
