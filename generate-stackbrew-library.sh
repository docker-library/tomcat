#!/bin/bash
set -eu

declare -A latestVariant=(
	[7]='jre7'
	[8.0]='jre7'
	[8.5]='jre8'
	[9.0]='jre10'
)
declare -A aliases=(
	[8.5]='8 latest'
	[9.0]='9'
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

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
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|microsoft\/[^:]+)(:|$)/ {
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
	for variant in jre{7,8,9,10}{,-{slim,alpine}}; do
		[ -f "$version/$variant/Dockerfile" ] || continue

		commit="$(dirCommit "$version/$variant")"

		fullVersion="$(git show "$commit":"$version/$variant/Dockerfile" | awk '$1 == "ENV" && $2 == "TOMCAT_VERSION" { print $3; exit }')"

		versionAliases=()
		while [ "$fullVersion" != "$version" -a "${fullVersion%[.-]*}" != "$fullVersion" ]; do
			versionAliases+=( $fullVersion )
			fullVersion="${fullVersion%[.-]*}"
		done
		versionAliases+=(
			$version
			${aliases[$version]:-}
		)

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		subVariant="${variant#*-}"
		[ "$subVariant" != "$variant" ] || subVariant=

		if [ "$variant" = "${latestVariant[$version]}" ]; then
			variantAliases+=( "${versionAliases[@]}" )
		elif [ "$subVariant" ] && [ "${variant%-$subVariant}" = "${latestVariant[$version]}" ]; then
			subVariantAliases=( "${versionAliases[@]/%/-$subVariant}" )
			subVariantAliases=( "${subVariantAliases[@]//latest-/}" )
			variantAliases+=( "${subVariantAliases[@]}" )
		fi

		variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$version/$variant/Dockerfile")"
		variantArches="${parentRepoToArches[$variantParent]}"

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: $(join ', ' $variantArches)
			GitCommit: $commit
			Directory: $version/$variant
		EOE
	done
done
