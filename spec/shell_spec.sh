#!/bin/sh

# The suite reports in TAP (Test Anything Protocol) version 14
# can be read by eye or piped into any TAP consumer (prove, tappy, tap-parser,
# faucet...). Human-readable detail -- timings, diffs, stderr from a command
# that was supposed to fail -- goes out as TAP comments and YAML diagnostic
# blocks, both of which a consumer will either display or ignore, so nothing
# has to be traded off against the machine-readable form.
# See https://testanything.org/ for more on TAP.
#
# Exit status is 0 when every test point passed, 1 otherwise.
#
# Usage: spec/shell_spec.sh [test file]...
#
# With no arguments every file in spec/tests/ runs. Name one or more to run
# only those: `path`, `path_test`, `path_test.sh` and `spec/tests/path_test.sh`
# all name the same file. Whatever is named, setup runs first, since the other
# files read the tree it lays out, and the files run in their usual order
# rather than the order they were named in.

trap cleanup 1 2 3 6

EXECUTABLE="${PATH_HELPER_EXECUTABLE:-${PWD}/exe/path_helper}"

SPEC_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SPEC_DIR/lib/test_helpers.sh"

echo "TAP version 14"

# --- Test files -------------------------------------------------------------

# Every test file, in the order they run. The tests share the TAP counters, so
# the files are sourced rather than run. setup has to come first; the order of
# the rest does not matter.
TEST_FILES="setup path error edge_case"

# The files named on the command line, reduced to the short names above. They
# are checked before the guard so that a mistyped name is reported even where
# the suite will not run.
selected_files=""
for selected_arg in "$@"; do
	selected_name=${selected_arg##*/}
	selected_name=${selected_name%.sh}
	selected_name=${selected_name%_test}
	case " $TEST_FILES " in
		*" $selected_name "*)
			selected_files="$selected_files $selected_name"
			;;
		*)
			echo "Bail out! no test file named '$selected_arg' (choose from: $TEST_FILES)"
			exit 1
			;;
	esac
done

# is_selected <name>
is_selected(){
	[ -z "$selected_files" ] || [ "$1" = setup ] ||
	case " $selected_files " in
		*" $1 "*) true ;;
		*) false ;;
	esac
}

# --- Guard ------------------------------------------------------------------

if [ -z "$PATH_HELPER_DOCKER_INSTANCE" ]; then
	echo "1..0 # SKIP set PATH_HELPER_DOCKER_INSTANCE to run these destructive tests"
	tap_comment "These tests are destructive,"
	tap_comment "which is why there is a Docker setup for them."
	tap_comment "If you really want to run them"
	tap_comment "then you need to set PATH_HELPER_DOCKER_INSTANCE."
	tap_comment "If it is empty this will not run."
	tap_comment "Caveat emptor."
	exit 0
fi

# --- Run --------------------------------------------------------------------

TMPDIR=$(mktemp -d)
cleanup

running_files=""
for test_file in $TEST_FILES; do
	if is_selected "$test_file"; then
		running_files="$running_files $test_file"
	fi
done

if [ -n "$selected_files" ]; then
	tap_comment "Running only:$running_files"
fi

for test_file in $running_files; do
	. "$SPEC_DIR/tests/${test_file}_test.sh"
done

tap_plan

cleanup

exit $tap_failed
