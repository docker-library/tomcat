#!/bin/bash
set -e

declare -A aliases
aliases=(
	[8]='latest'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/docker-library/tomcat'

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

for version in "${versions[@]}"; do
	commit="$(git log -1 --format='format:%H' -- "$version")"
	
	fullVersion="$(grep -m1 'ENV TOMCAT_VERSION ' "$version/Dockerfile" | cut -d' ' -f3)"
	majorVersion=${fullVersion%.*}
	
	versionAliases=()
	bases=( $fullVersion $majorVersion $version ${aliases[$version]} )
	for base in "${bases[@]}"; do
		versionAliases+=( "$base-jre7" )
		versionAliases+=( "$base" )
	done
	
	echo
	for va in "${versionAliases[@]}"; do
		echo "$va: ${url}@${commit} $version"
	done
done
