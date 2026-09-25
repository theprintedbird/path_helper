#!/bin/sh
# Greps the test harness for shell forms that only exist in GNU userland and
# would silently misbehave or error out under BSD userland (macOS) --
# `sed -i`, `stat`, `readlink`, `realpath`, `date +%N`, and a few other
# GNU-only flags. Non-POSIX forms that BSD and busybox both have anyway
# (`grep -o`, `head -c`, `tail -5`) are not flagged. `mktemp`/`mktemp -d` are
# fine (BSD/macOS has had both forms since 10.11) so they are not checked here.
#
# Run from the project root: `sh spec/lint_portability.sh` (also wired into
# `make lint`). Exits non-zero and prints the offending lines if it finds any.
#
# This is plain POSIX sh -- no `grep -P`, no bashisms -- since it has to run
# on macOS (BSD grep), Alpine (busybox grep) and Ubuntu (GNU grep) alike, the
# same three userlands the suite itself runs under.

status=0

# The files a macOS (or any) CI job actually executes: the harness itself and
# the composite actions' `run:` steps. docker/*.sh only ever runs inside the
# Linux build images, so it is not held to this rule.
files="spec/shell_spec.sh spec/lib/test_helpers.sh"
for f in spec/tests/*.sh spec/lib/coverage/*.sh; do
	[ -f "$f" ] && files="$files $f"
done
for f in .github/actions/*/action.yml; do
	[ -f "$f" ] && files="$files $f"
done

# One grep pattern per line, checked with -w/-E so e.g. "stat" doesn't flag
# "test_setup" or "\<statement\>". Comment lines (optionally indented '#')
# are stripped first, since the harness deliberately *mentions* some of these
# in prose explaining why they are avoided (see get_time_ns in
# spec/lib/test_helpers.sh) -- those mentions are not the thing being guarded
# against.
patterns="sed[ 	]+-[a-zA-Z]*i
sed[ 	]+-[a-zA-Z]*r
stat
readlink
realpath
date[ 	]+\+%N
grep[ 	]+-[a-zA-Z]*P
xargs[ 	]+-[a-zA-Z]*r
find[ 	].*-printf
echo[ 	]+-e"

for file in $files; do
	stripped=$(grep -vE '^[ 	]*#' "$file")
	old_ifs=$IFS
	IFS='
'
	for pattern in $patterns; do
		IFS=$old_ifs
		hits=$(printf '%s\n' "$stripped" | grep -nwE -- "$pattern") && {
			echo "spec/lint_portability.sh: $file matches GNU-only form '$pattern':"
			printf '%s\n' "$hits" | sed 's/^/  /'
			status=1
		}
		IFS='
'
	done
	IFS=$old_ifs
done

if [ "$status" -eq 0 ]; then
	echo "spec/lint_portability.sh: ok, no GNU-only shell forms found in $(printf '%s\n' "$files" | wc -w | tr -d ' ') files"
fi

exit "$status"
