#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

travisEnv=
for version in "${versions[@]}"; do
	majorVersion="${version%%.*}"
	fullVersion="$(curl -fsSL --compressed "https://www.apache.org/dist/tomcat/tomcat-$majorVersion/" | grep '<a href="v'"$version." | sed -r 's!.*<a href="v([^"/]+)/?".*!\1!' | sort -V | tail -1)"
	
	for variant in "$version"/*/; do
		variant="$(basename "$variant")"
		javaVariant="${variant%%-*}"
		subVariant="${variant#$javaVariant-}"
		[ "$subVariant" != "$variant" ] || subVariant=
		
		baseImage='java'
		case "$javaVariant" in
			jre*|jdk*)
				baseImage+=":${javaVariant:3}-${javaVariant:0:3}${subVariant:+-$subVariant}" # ":7-jre" or ":7-jre-alpine"
				;;
			*)
				echo >&2 "not sure what to do with $version/$variant re: baseImage; skipping"
				continue
				;;
		esac
		
		(
			set -x
			if [ "$majorVersion" != '6' ]; then
				cp -v "Dockerfile${subVariant:+-$subVariant}.template" "$version/$variant/Dockerfile"
			fi
			sed -ri '
				s/^(FROM) .*/\1 '"$baseImage"'/;
				s/^(ENV TOMCAT_MAJOR) .*/\1 '"$majorVersion"'/;
				s/^(ENV TOMCAT_VERSION) .*/\1 '"$fullVersion"'/;
			' "$version/$variant/Dockerfile"
		)
		
		travisEnv='\n  - '"VERSION=$version VARIANT=$variant$travisEnv"
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
