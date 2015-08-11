#!/bin/bash
set -e

declare -A aliases
aliases=(
)
defaultVersion='8'
defaultJava='7'
defaultSuffix="jre${defaultJava}"

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/docker-library/tomcat'

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

for version in "${versions[@]}"; do
	commit="$(cd "$version" && git log -1 --format='format:%H' -- Dockerfile $(awk 'toupper($1) == "COPY" { for (i = 2; i < NF; i++) { print $i } }' Dockerfile))"
	
	majorVersion="${version%%-*}"
	suffix="${version#*-}" # "jre7"
	
	fullVersion="$(grep -m1 'ENV TOMCAT_VERSION ' "$version/Dockerfile" | cut -d' ' -f3)"
	majorMinorVersion="${fullVersion%.*}"
	
	versionAliases=( $fullVersion-$suffix $majorMinorVersion-$suffix $majorVersion-$suffix ) # 8.0.14-jre7 8.0-jre7 8-jre7
	if [ "$majorVersion" = "$defaultVersion" ]; then
		versionAliases+=( $suffix ) # jre7
	fi
	
	if [ "$suffix" = "$defaultSuffix" ]; then
		versionAliases+=( $fullVersion $majorMinorVersion $majorVersion ) # 8.0.14 8.0 8
		if [ "$majorVersion" = "$defaultVersion" ]; then
			versionAliases+=( latest )
		fi
	fi
	
	versionAliases+=( ${aliases[$version]} )
	
	echo
	for va in "${versionAliases[@]}"; do
		echo "$va: ${url}@${commit} $version"
	done
done
