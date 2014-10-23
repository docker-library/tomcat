#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
	fullVersion="$(curl -sSL --compressed "https://www.apache.org/dist/tomcat/tomcat-$version/" | grep '<a href="v'"$version." | sed -r 's!.*<a href="v([^"/]+)/?".*!\1!' | sort -V | tail -1)"
	(
		set -x
		sed -ri '
			s/^(ENV TOMCAT_MAJOR) .*/\1 '"$version"'/;
			s/^(ENV TOMCAT_VERSION) .*/\1 '"$fullVersion"'/;
		' "$version/Dockerfile"
	)
done
