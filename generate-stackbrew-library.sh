#!/bin/bash
set -e

declare -A latestVariant=(
	[6]='jre7'
	[7]='jre7'
	[8.0]='jre7'
	[8.5]='jre8'
)
latestVersion='8.0'
declare -A aliases=(
	[8.0]='8'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/docker-library/tomcat'

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'

for version in "${versions[@]}"; do
	for variant in "$version"/*/; do
		variant="$(basename "$variant")"
		
		commit="$(cd "$version/$variant" && git log -1 --format='format:%H' -- Dockerfile $(awk 'toupper($1) == "COPY" { for (i = 2; i < NF; i++) { print $i } }' Dockerfile))"
		fullVersion="$(grep -m1 'ENV TOMCAT_VERSION ' "$version/$variant/Dockerfile" | cut -d' ' -f3)"
		
		versionAliases=()
		while [ "$fullVersion" != "$version" -a "${fullVersion%[.-]*}" != "$fullVersion" ]; do
			versionAliases+=( $fullVersion )
			fullVersion="${fullVersion%[.-]*}"
		done
		versionAliases+=( $version ${aliases[$version]} )
		
		if [ "$variant" = "${latestVariant[$version]}" ]; then
			versionAliases=( "${versionAliases[@]/%/-$variant}" "${versionAliases[@]}" )
			if [ "$version" = "$latestVersion" ]; then
				versionAliases+=( latest )
			fi
		else
			versionAliases=( "${versionAliases[@]/%/-$variant}" )
		fi
		
		echo
		for va in "${versionAliases[@]}"; do
			echo "$va: ${url}@${commit} $version/$variant"
		done
	done
done
