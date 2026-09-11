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

trap cleanup 1 2 3 6

EXECUTABLE="${PATH_HELPER_EXECUTABLE:-${PWD}/exe/path_helper}"

SPEC_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SPEC_DIR/lib/test_helpers.sh"

echo "TAP version 14"

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

# The tests share the TAP counters, so they are sourced rather than run.
# setup_test.sh has to come first; the order of the rest does not matter.
. "$SPEC_DIR/tests/setup_test.sh"
. "$SPEC_DIR/tests/path_test.sh"
. "$SPEC_DIR/tests/error_test.sh"
. "$SPEC_DIR/tests/edge_case_test.sh"

tap_plan

cleanup

exit $tap_failed
