#!/bin/bash
set -e

if ! [ $# -gt 0 ]; then
	echo >&2 "usage: $0 version [version ...]"
	echo >&2 "   ie: $0 0.8.0"
	echo >&2 "       $0 0.7.6 0.7.5"
	exit 1
fi

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

urlBase='http://get.docker.com.s3.amazonaws.com/builds'
testUrlBase='http://test.docker.com.s3.amazonaws.com/builds'

declare -A platforms=(
	[darwin]=Darwin
	[linux]=Linux
	[freebsd]=FreeBSD
	[windows]=Windows
)
declare -A arches=(
	[386]=i386
	[amd64]=x86_64
	[armel]=armel
	[armhf]=armhf
)

download() {
	version="$1"
	platform="$2"
	arch="$3"
	
	thisUrlBase="$urlBase"
	if [[ "$version" == *rc* ]]; then
		thisUrlBase="$testUrlBase"
	fi
	
	pwd
	targetBin="docker-$version"
	#target="$targetBin"
	target="$targetBin.tgz"
	if [ "$platform" = 'windows' ]; then
		target="$targetBin.zip"
	fi
	url="$thisUrlBase/${platforms[$platform]}/${arches[$arch]}/$target"
	( set -x; curl -fSL'#' "$url" -o "$target" ) || true
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
		echo "awww, no docker $version at $thisUrlBase for $platform/$arch"
		( set -x; rm -f "$target" )
	fi
}

while [ $# -gt 0 ]; do
	version="$1"
	shift
	
	download "$version" linux amd64
	
	case "$version" in
		#*rc*) ;;
		*) ./api-version/symlink.sh "./docker-$version" ;;
	esac
	
	for p in */; do
		p="${p%/}"
		case "$p" in
			api-version) continue ;;
		esac
		(
			cd "$p"
			for a in */; do
				a="${a%/}"
				(
					cd "$a"
					download "$version" "$p" "$a"
				)
			done
		)
	done
done
