#!/bin/bash
set -eo pipefail

#Download latest LIB version
APACHE_MIRROR=$(curl -s "http://www.apache.org/dyn/closer.cgi/tomcat/?as_json=1" | grep -Po '\"preferred\": \"\K[^\"]+')
`curl -fsSL --compressed "${APACHE_MIRROR}apr/" | grep '<a href="apr' > /tmp/apr.html`
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
	majorVersion="${version%%-*}" # "6"
	suffix="${version#*-}" # "jre7"
	javaMajorVersion="${version#*-jre}" # "jre7"

	baseImage='java'
	case "$suffix" in
		jre*|jdk*)
			baseImage+=":${suffix:3}-${suffix:0:3}" # ":7-jre"
			;;
	esac

	cp Dockerfile $version/Dockerfile

	fullVersion="$(curl -fsSL --compressed "${APACHE_MIRROR}tomcat/tomcat-$majorVersion/" | grep '<a href="v'"$majorVersion." | sed -r 's!.*<a href="v([^"/]+)/?".*!\1!' | sort -V | tail -1)"
	(
		set -x
		sed -ri '
			s/^(FROM) .*/\1 '"$baseImage"'/;
			s/^(ENV TOMCAT_MAJOR) .*/\1 '"$majorVersion"'/;
			s/^(ENV TOMCAT_VERSION) .*/\1 '"$fullVersion"'/;
			s/^(ENV APR_VER) .*/\1 '"$aprVersion"'/;
			s/^(ENV APR_UTIL_VER) .*/\1 '"$aprUtilVersion"'/;
			s/^(ENV JAVA_MAJOR_VER) .*/\1 '"$javaMajorVersion"'/;
			s/(TOMCAT_MAJOR_VERSION)/'"$majorVersion"'/;
		' "$version/Dockerfile"
	)
	travisEnv='\n  - VERSION='"$version$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
