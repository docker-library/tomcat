#!/bin/bash
set -eo pipefail

#Download latest LIB version
tomcatNativeVersion_1_1="$(curl -s "https://www.apache.org/dist/tomcat/tomcat-connectors/native/" | grep '<a href="1.1.' | sed -r 's!.*<a href="(1.1.[^"/]+)/".*!\1!' | sort -V | tail -1)"
tomcatNativeVersion_1_2="$(curl -s "https://www.apache.org/dist/tomcat/tomcat-connectors/native/" | grep '<a href="1.2.' | sed -r 's!.*<a href="(1.2.[^"/]+)/".*!\1!' | sort -V | tail -1)"
`curl -fsSL --compressed "https://www.apache.org/dist/apr/" | grep '<a href="apr' > /tmp/apr.html`
aprVersion="$(cat /tmp/apr.html | grep '<a href="apr-[0-9].[0-9].[0-9].tar.gz"' | sed -r 's!.*<a href="([^"/]+).tar.gz".*!\1!' | sort -V | tail -1)"
aprUtilVersion="$(cat /tmp/apr.html | grep '<a href="apr-util-[0-9].[0-9].[0-9].tar.gz"' | sed -r 's!.*<a href="([^"/]+).tar.gz".*!\1!' | sort -V | tail -1)"
rm /tmp/apr.html

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
        javaMajorVersion="NotFound" # "7"

		baseImage='java'
		case "$variant" in
			jre*)
				baseImage+=":${variant:3}-${variant:0:3}" # ":7-jre"
				javaMajorVersion="${variant#jre}" # "7"
				;;
			jdk*)
				baseImage+=":${variant:3}-${variant:0:3}" # ":7-jdk"
				javaMajorVersion="${variant#jdk}" # "7"
				;;
			*)
				echo >&2 "not sure what to do with $version/$variant re: baseImage; skipping"
				continue
				;;
		esac

		(
			set -x
			sed -ri '
				s/^(FROM) .*/\1 '"$baseImage"'/;
				s/^(ENV TOMCAT_MAJOR) .*/\1 '"$majorVersion"'/;
				s/^(ENV TOMCAT_VERSION) .*/\1 '"$fullVersion"'/;
				s/^(ENV APR_VER) .*/\1 '"$aprVersion"'/;
				s/^(ENV APR_UTIL_VER) .*/\1 '"$aprUtilVersion"'/;
				s/^(ENV JAVA_MAJOR_VER) .*/\1 '"$javaMajorVersion"'/;
				s/^(ENV TOMCAT_NATIVE_VERSION_1_1) .*/\1 '"$tomcatNativeVersion_1_1"'/;
				s/^(ENV TOMCAT_NATIVE_VERSION_1_2) .*/\1 '"$tomcatNativeVersion_1_2"'/;
			' "$version/$variant/Dockerfile"
		)

		travisEnv='\n  - '"VERSION=$version VARIANT=$variant$travisEnv"
	done
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
