#!/bin/sh
# Cuts a GitHub release for TAG with gh: title "Release TAG", the notes from
# NOTES_FILE and every ASSET attached. release.yml's last step runs it, and it
# can be run by hand from a checkout (gh logged in, or GH_TOKEN set).
#
# If the release already exists (a re-run, or a draft made by hand), its
# assets are uploaded over any of the same name and it is then retitled, given
# these notes and published -- never a draft or prerelease. Otherwise it is
# created, published. --target COMMIT only matters when the tag doesn't exist
# yet: GitHub then makes it at COMMIT (without it, at the default branch's
# head); for a tag that already exists it is ignored.
#
# gh finds the repository from GH_REPO if set, else the checkout's remote.
# gh reads `path#label` as an asset with a display label, so an asset path
# containing `#` is refused rather than silently renamed.
# Plain POSIX sh with nothing GNU-only, as it is run by hand on a Mac.
set -eu

me=${0##*/}

usage() {
	cat <<EOF
Usage: $me [--target COMMIT] TAG NOTES_FILE ASSET...

Creates the GitHub release TAG, titled "Release TAG", with the notes in
NOTES_FILE and each ASSET attached; or, if it exists already, replaces its
assets, title and notes and publishes it.

  --target COMMIT  where to make the tag if it doesn't exist yet
                   (default: the default branch's head)
  -h, --help       show this help
EOF
}

die() {
	printf '%s: %s\n' "$me" "$1" >&2
	printf 'See %s --help.\n' "$me" >&2
	exit 2
}

target=
while [ $# -gt 0 ]; do
	case $1 in
	-h | --help)
		usage
		exit 0
		;;
	--target)
		[ $# -ge 2 ] && [ -n "$2" ] || die "--target needs a commit"
		target=$2
		shift 2
		;;
	--target=*)
		target=${1#--target=}
		[ -n "$target" ] || die "--target needs a commit"
		shift
		;;
	--)
		shift
		break
		;;
	-?*) die "unknown option: $1" ;;
	*) break ;;
	esac
done

[ $# -ge 3 ] || die "needs a tag, a notes file and at least one asset"
tag=$1
notes=$2
shift 2

case $tag in
"" | -*) die "not a tag: '$tag'" ;;
esac
[ -f "$notes" ] && [ -r "$notes" ] || die "no readable notes file: $notes"
for asset in "$@"; do
	case $asset in
	*'#'*) die "an asset path can't contain '#': $asset" ;;
	esac
	[ -f "$asset" ] && [ -r "$asset" ] || die "no readable asset: $asset"
done
command -v gh >/dev/null 2>&1 || {
	printf '%s: gh not found on PATH (brew install gh, or https://cli.github.com/)\n' "$me" >&2
	exit 1
}

title="Release $tag"

# The flags go before `--` so no tag or asset name is taken for one.
if gh release view "$tag" >/dev/null 2>&1; then
	printf '%s: release %s exists; replacing its assets, title and notes\n' "$me" "$tag" >&2
	gh release upload --clobber -- "$tag" "$@"
	if [ -n "$target" ]; then
		gh release edit --title "$title" --notes-file "$notes" \
			--draft=false --prerelease=false --target "$target" -- "$tag"
	else
		gh release edit --title "$title" --notes-file "$notes" \
			--draft=false --prerelease=false -- "$tag"
	fi
else
	printf '%s: creating release %s\n' "$me" "$tag" >&2
	if [ -n "$target" ]; then
		gh release create --title "$title" --notes-file "$notes" \
			--target "$target" -- "$tag" "$@"
	else
		gh release create --title "$title" --notes-file "$notes" -- "$tag" "$@"
	fi
fi
