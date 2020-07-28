#!/bin/bash
set -eu

defaultVendorVariant='openjdk-buster'
declare -A latestVariant=(
	[7]="jdk8-$defaultVendorVariant"
	[8.0]="jdk8-$defaultVendorVariant"
	[8.5]="jdk8-$defaultVendorVariant"
	[9.0]="jdk11-$defaultVendorVariant"
	[10.0]="jdk11-$defaultVendorVariant"
)
declare -A vendorAliases=(
	['openjdk-buster']='openjdk'
	['openjdk-slim-buster']='openjdk-slim'
	['openjdk-oraclelinux7']='openjdk-oracle'
)
declare -A aliases=(
	[8.5]='8'
	[9.0]='9 latest'
	[10.0]='10'
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

# sort version numbers with highest first
IFS=$'\n'; versions=( $(echo "${versions[*]}" | sort -rV) ); unset IFS

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						print $i
					}
				}
			')
	)
}

getArches() {
	local repo="$1"; shift
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -g -A parentRepoToArches=( $(
		find -name 'Dockerfile' -exec awk '
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|.*\/.*)(:|$)/ {
					print "'"$officialImagesUrl"'" $2
				}
			' '{}' + \
			| sort -u \
			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
	) )"
}
getArches 'tomcat'

cat <<-EOH
# this file is generated via https://github.com/docker-library/tomcat/blob/$(fileCommit "$self")/$self

Maintainers: Tianon Gravi <admwiggin@gmail.com> (@tianon),
             Joseph Ferguson <yosifkit@gmail.com> (@yosifkit)
GitRepo: https://github.com/docker-library/tomcat.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version in "${versions[@]}"; do
	for javaVariant in {jdk,jre}{14,11,8}; do
		# OpenJDK, followed by all other variants alphabetically
		for vendorVariant in {openjdk{-oraclelinux7,{,-slim}-buster},adoptopenjdk-{hotspot,openj9},corretto}; do
			variant="$javaVariant-$vendorVariant"
			dir="$version/$javaVariant/$vendorVariant"
			[ -f "$dir/Dockerfile" ] || continue

			commit="$(dirCommit "$dir")"

			fullVersion="$(awk '$1 == "ENV" && $2 == "TOMCAT_VERSION" { print $3; exit }' "$dir/Dockerfile")"
			[ -n "$fullVersion" ]

			versionAliases=()
			while [ "$fullVersion" != "$version" -a "${fullVersion%[.-]*}" != "$fullVersion" ]; do
				versionAliases+=( $fullVersion )
				fullVersion="${fullVersion%[.-]*}"
			done
			versionAliases+=(
				$version
				${aliases[$version]:-}
			)

			# "jdk8-openjdk-slim"
			variantAliases=( "${versionAliases[@]/%/-$variant}" )
			variantAliases=( "${variantAliases[@]//latest-/}" )

			for vendorAlias in ${vendorAliases[$vendorVariant]:-}; do
				aliasAliases=( "${versionAliases[@]/%/-$javaVariant-$vendorAlias}" )
				aliasAliases=( "${aliasAliases[@]//latest-/}" )
				variantAliases+=( "${aliasAliases[@]}" )
			done

			# "jdk8"
			if [ "$vendorVariant" = "$defaultVendorVariant" ]; then
				javaAliases=( "${versionAliases[@]/%/-$javaVariant}" )
				javaAliases=( "${javaAliases[@]//latest-/}" )
				variantAliases+=( "${javaAliases[@]}" )
			fi

			# "latest"
			if [ "$variant" = "${latestVariant[$version]}" ]; then
				variantAliases+=( "${versionAliases[@]}" )
			fi

			variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$dir/Dockerfile")"
			[ -n "$variantParent" ]
			variantArches="${parentRepoToArches[$variantParent]}"

			echo
			cat <<-EOE
				Tags: $(join ', ' "${variantAliases[@]}")
				Architectures: $(join ', ' $variantArches)
				GitCommit: $commit
				Directory: $dir
			EOE
			constraints="$(bashbrew cat --format '{{ .TagEntry.Constraints | join ", " }}' "https://github.com/docker-library/official-images/raw/master/library/$variantParent")"
			[ -z "$constraints" ] || echo "Constraints: $constraints"
		done
	done
done
