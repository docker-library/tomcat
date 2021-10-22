#!/bin/bash
set -eu

declare -A aliases=(
	[8.5]='8'
	[9.0]='9'
	[10.0]='10 latest'
	[10.1]=''
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys_unsorted | sort_by(tonumber) | reverse | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

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
		find "$@" -name 'Dockerfile' -exec awk '
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|.*\/.*)(:|$)/ {
					print "'"$officialImagesUrl"'" $2
				}
			' '{}' + \
			| sort -u \
			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
	) )"
}
getArches 'tomcat' "$@"

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

for version; do
	export version
	variants="$(jq -r '.[env.version].variants | map(@sh) | join(" ")' versions.json)"
	eval "variants=( $variants )"

	fullVersion="$(jq -r '.[env.version].version' versions.json)"

	versionAliases=()
	while [ "$fullVersion" != "$version" -a "${fullVersion%[.-]*}" != "$fullVersion" ]; do
		versionAliases+=( $fullVersion )
		fullVersion="${fullVersion%[.-]*}"
	done
	versionAliases+=(
		$version
		${aliases[$version]:-}
	)

	latestVariant="$(jq -r '
		.[env.version].variants
		| map(
			select(
				(
					# LTS Java releases
					# TODO add jdk17 once the longevity of vanilla builds from http://jdk.java.net/17/ are determined (or alternative vanilla builds are made available)
					startswith("jdk11")
					or startswith("jdk8")
				) and (
					split("/")[1]
					| test("^openjdk-(?!slim-)")
				)
			)
		)[0]
	' versions.json)"

	defaultOpenjdkVariant="$(jq -r '
		.[env.version].variants
		| map(
			split("/")[1]
			| select(test("^openjdk-(?!slim-)"))
		)[0]
	' versions.json)"
	defaultOpenjdkSlimVariant="$(jq -r '
		.[env.version].variants
		| map(
			split("/")[1]
			| select(test("^openjdk-slim-"))
		)[0]
	' versions.json)"
	defaultTemurinVariant="$(jq -r '
		.[env.version].variants
		| map(
			split("/")[1]
			| select(test("^temurin-"))
		)[0]
	' versions.json)"
	declare -A vendorAliases=(
		["$defaultOpenjdkVariant"]='openjdk'
		["$defaultOpenjdkSlimVariant"]='openjdk-slim'
		["$defaultTemurinVariant"]='temurin'
	)

	for variantDir in "${variants[@]}"; do
		javaVariant="$(dirname "$variantDir")" # "jdk8", "jre11", etc
		vendorVariant="$(basename "$variantDir")" # "openjdk-slim-buster", "corretto", etc.
		variant="$javaVariant-$vendorVariant"
		dir="$version/$variantDir"
		[ -f "$dir/Dockerfile" ] || continue

		commit="$(dirCommit "$dir")"

		# "jdk8-openjdk-slim"
		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		for vendorAlias in ${vendorAliases[$vendorVariant]:-}; do
			aliasAliases=( "${versionAliases[@]/%/-$javaVariant-$vendorAlias}" )
			aliasAliases=( "${aliasAliases[@]//latest-/}" )
			variantAliases+=( "${aliasAliases[@]}" )
		done

		# "jdk8"
		if [ "$vendorVariant" = "$defaultOpenjdkVariant" ]; then
			javaAliases=( "${versionAliases[@]/%/-$javaVariant}" )
			javaAliases=( "${javaAliases[@]//latest-/}" )
			variantAliases+=( "${javaAliases[@]}" )
		fi

		# "latest"
		if [ "$variantDir" = "$latestVariant" ]; then
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
		#constraints="$(bashbrew cat --format '{{ .TagEntry.Constraints | join ", " }}' "https://github.com/docker-library/official-images/raw/master/library/$variantParent")"
		#[ -z "$constraints" ] || echo "Constraints: $constraints"
	done
done
