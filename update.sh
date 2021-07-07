#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

# docker run -it --rm buildpack-deps:curl
# curl -fsSL 'https://www.apache.org/dist/tomcat/tomcat-8/KEYS' | gpg --import
# gpg --batch --fingerprint | tr -d ' ' | grep -oE '^[0-9A-F]{40}$' | sort
declare -A gpgKeys=(
	# gpg: key 10C01C5A2F6059E7: public key "Mark E D Thomas <markt@apache.org>" imported
	[10]='
		A9C5DF4D22E99998D9875A5110C01C5A2F6059E7
	'

	# gpg: key 6FB21E8933C60243: public key "Mark E D Thomas <markt@apache.org>" imported
	# gpg: key 10C01C5A2F6059E7: public key "Mark E D Thomas <markt@apache.org>" imported
	# gpg: key 68248959359E722B: public key "Remy Maucherat <remm@apache.org>" imported
	[9]='
		48F8E69F6390C9F25CFEDCD268248959359E722B
		A9C5DF4D22E99998D9875A5110C01C5A2F6059E7
		DCFD35E0BF8CA7344752DE8B6FB21E8933C60243
	'

	# gpg: key 6A3AD3F4F22C4FED: public key "Andy Armstrong <andy@tagish.com>" imported
	# gpg: key D3EFE6B686867BA6: public key "Jean-Frederic Clere (jfclere) <JFrederic.Clere@fujitsu-siemens.com>" imported
	# gpg: key ACB77FC2E86E29AC: public key "kevin seguin <seguin@apache.org>" imported
	# gpg: key 1931D684307A10A5: public key "Henri Gomez <hgomez@users.sourceforge.net>" imported
	# gpg: key 1C506407564C17A3: public key "Mladen Turk (*** DEFAULT SIGNING KEY ***) <mturk@apache.org>" imported
	# gpg: key 266191C37C037D42: public key "Yoav Shapira <yoavs@apache.org>" imported
	# gpg: key 6FB21E8933C60243: public key "Mark E D Thomas <markt@apache.org>" imported
	# gpg: key 10C01C5A2F6059E7: public key "Mark E D Thomas <markt@apache.org>" imported
	# gpg: key 3C370389288584E7: public key "R�my Maucherat <remm@apache.org>" imported
	# gpg: key 3B7BBB100D811BBE: public key "Yoav Shapira <yoavs@computer.org>" imported
	# gpg: key F72C284D731FABEE: public key "Tim Whittington (CODE SIGNING KEY) <timw@apache.org>" imported
	# gpg: key 35CD23C10D498E23: public key "Mladen Turk (Default signing key) <mturk@apache.org>" imported
	# gpg: key A54AD08EA7A0233C: public key "Jeremy Boynes <jboynes@apache.org>" imported
	# gpg: key FA0C35EA8AA299F1: public key "Konstantin Kolinko (CODE SIGNING KEY) <kkolinko@apache.org>" imported
	# gpg: key F3AD5C94A67F707E: public key "Christopher Schultz <chris@christopherschultz.net>" imported
	[8]='
		05AB33110949707C93A279E3D3EFE6B686867BA6
		07E48665A34DCAFAE522E5E6266191C37C037D42
		47309207D818FFD8DCD3F83F1931D684307A10A5
		541FBE7D8F78B25E055DDEE13C370389288584E7
		5C3C5F3E314C866292F359A8F3AD5C94A67F707E
		61B832AC2F1C5A90F0F9B00A1C506407564C17A3
		765908099ACF92702C7D949BFA0C35EA8AA299F1
		79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED
		8B46CA49EF4837B8C7F292DAA54AD08EA7A0233C
		9BA44C2621385CB966EBA586F72C284D731FABEE
		A27677289986DB50844682F8ACB77FC2E86E29AC
		A9C5DF4D22E99998D9875A5110C01C5A2F6059E7
		DCFD35E0BF8CA7344752DE8B6FB21E8933C60243
		F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE
		F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23
	'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

# sort version numbers with lowest first
IFS=$'\n'; versions=( $(sort -V <<<"${versions[*]}") ); unset IFS

for version in "${versions[@]}"; do
	majorVersion="${version%%.*}"

	versionGpgKeys=( ${gpgKeys[$majorVersion]} )
	if [ "${#versionGpgKeys[@]}" -eq 0 ]; then
		echo >&2 "error: missing GPG fingerprints for $majorVersion"
		exit 1
	fi

	possibleVersions="$(
		curl -fsSL --compressed "https://www-us.apache.org/dist/tomcat/tomcat-$majorVersion/" \
			| grep '<a href="v'"$version." \
			| sed -r 's!.*<a href="v([^"/]+)/?".*!\1!' \
			| sort -rV
	)"
	fullVersion=
	sha512=
	for possibleVersion in $possibleVersions; do
		if possibleSha512="$(
			curl -fsSL "https://www-us.apache.org/dist/tomcat/tomcat-$majorVersion/v$possibleVersion/bin/apache-tomcat-$possibleVersion.tar.gz.sha512" \
				| cut -d' ' -f1
		)" && [ -n "$possibleSha512" ]; then
			fullVersion="$possibleVersion"
			sha512="$possibleSha512"
			break
		fi
	done
	if [ -z "$fullVersion" ]; then
		echo >&2 "error: failed to find latest release for $version"
		exit 1
	fi

	echo "$version: $fullVersion ($sha512)"

	for javaDir in "$version"/{jre,jdk}{8,11,16}/; do
		javaDir="${javaDir%/}"
		javaVariant="$(basename "$javaDir")"
		javaVersion="${javaVariant#jdk}"
		javaVersion="${javaVersion#jre}" # "11", "8"
		javaVariant="${javaVariant%$javaVersion}" # "jdk", "jre"
		# all variants in reverse alphabetical order followed by OpenJDK
		for vendorDir in "$javaDir"/{corretto,adoptopenjdk-{openj9,hotspot},openjdk{-slim,}-buster}/; do
			vendorDir="${vendorDir%/}"
			vendor="$(basename "$vendorDir")"
			[ -d "$vendorDir" ] || continue

			template=
			baseImage=
			case "$vendor" in
				openjdk*-buster)
					template='apt'
					baseImage="openjdk:$javaVersion-$javaVariant"
					if vendorVariant="${vendor#openjdk-}" && [ "$vendorVariant" != "$vendor" ]; then
						baseImage+="-$vendorVariant"
					fi
					;;

				adoptopenjdk-hotspot | adoptopenjdk-openj9)
					template='apt'
					adoptVariant="${vendor#adoptopenjdk-}"
					baseImage="adoptopenjdk:$javaVersion-$javaVariant-$adoptVariant"
					;;

				corretto)
					template='yum'
					baseImage="amazoncorretto:$javaVersion"
					;;
			esac

			if [ -z "$template" ]; then
				echo >&2 "error: cannot determine template for '$vendorDir'"
				exit 1
			fi
			if [ -z "$baseImage" ]; then
				echo >&2 "error: cannot determine base image for '$vendorDir'"
				exit 1
			fi

			echo "  - $vendorDir: $baseImage ($template)"

			sed -r \
				-e 's/^(ENV TOMCAT_VERSION) .*/\1 '"$fullVersion"'/' \
				-e 's/^(FROM) .*/\1 '"$baseImage"'/' \
				-e 's/^(ENV TOMCAT_MAJOR) .*/\1 '"$majorVersion"'/' \
				-e 's/^(ENV TOMCAT_SHA512) .*/\1 '"$sha512"'/' \
				-e 's/^(ENV GPG_KEYS) .*/\1 '"${versionGpgKeys[*]}"'/' \
				"Dockerfile-$template.template" \
				> "$vendorDir/Dockerfile"
		done
	done
done
