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

# --- TAP output -------------------------------------------------------------

tap_count=0
tap_failed=0

echo "TAP version 14"

# A free-standing diagnostic line.
tap_comment(){
	echo "# $1"
}

# Pipe arbitrary text through this to make it TAP-safe. Any line beginning with
# a '#' is a comment, which is why the dumps below are comments rather than YAML
# block scalars: a diff can contain blank or space-indented lines, and those are
# what make hand-rolled block scalars ambiguous to a YAML parser.
# awk rather than sed because path output has no trailing newline, and awk's
# print terminates the last line for us instead of running the next line of
# output onto the end of it.
tap_comment_stream(){
	awk '{ print "# " $0 }'
}

# tap_comment_file <label> <file>
tap_comment_file(){
	tap_comment "--- $1 ---"
	tap_comment_stream < "$2"
	tap_comment "--- end $1 ---"
}

tap_ok(){
	tap_count=$((tap_count + 1))
	echo "ok $tap_count - $1"
}

tap_not_ok(){
	tap_count=$((tap_count + 1))
	tap_failed=1
	echo "not ok $tap_count - $1"
}

# tap_yaml <message> [key: value]...
# Emits the YAML diagnostic block belonging to the test point just printed.
# Keys are indented one level deeper than the block itself, so pass them
# pre-nested if they belong under `data:`.
tap_yaml(){
	local message="$1"
	shift
	echo "  ---"
	echo "  message: '$message'"
	echo "  severity: fail"
	if [ $# -gt 0 ]; then
		echo "  data:"
		for pair in "$@"; do
			echo "    $pair"
		done
	fi
	echo "  ..."
}

# The plan goes last because the number of test points is whatever the run
# actually emitted; TAP 14 allows a trailing plan.
tap_plan(){
	echo "1..$tap_count"
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

cleanup(){
	handle_error() {
		echo "Bail out! $1"
	}
	safe_remove() {
		local target="$1"
		if [ -d "$target" ]; then
			rm -rf "$target" || handle_error "Failed to remove $target"
		else
			rm -f "$target" || handle_error "Failed to remove $target"
		fi
	}

	if [ -d "$HOME/Library/Paths" ]; then
		safe_remove "$HOME/Library/Paths"
	fi
	if [ -d "$HOME/.config/paths" ]; then
		safe_remove "$HOME/.config/paths"
	fi
	# The target of the /etc/paths.d symlink (see below). /etc/paths.d itself is
	# removed with the rest of /etc, and `rm -rf` on a symlink takes the link
	# rather than what it points at, so the target has to be named separately.
	if [ -d "$HOME/symlinked-paths.d" ]; then
		safe_remove "$HOME/symlinked-paths.d"
	fi
	# Likewise the target of the symlinked fragment file in paths.d.
	if [ -d "$HOME/symlinked-fragments" ]; then
		safe_remove "$HOME/symlinked-fragments"
	fi
	if [ -d /etc/paths.d ]; then
		safe_remove /etc/paths.d
	fi
	if [ -d /etc/manpaths.d ]; then
		safe_remove /etc/manpaths.d
		safe_remove /etc/manpaths
	fi
	if [ -d /etc/dyld_fallback_framework_paths.d ]; then
		safe_remove /etc/dyld_fallback_framework_paths.d
		safe_remove /etc/dyld_fallback_framework_paths
	fi
	if [ -d /etc/dyld_fallback_library_paths.d ]; then
		safe_remove /etc/dyld_fallback_library_paths.d
		safe_remove /etc/dyld_fallback_library_paths
	fi
	if [ -d /etc/dyld_framework_paths.d ]; then
		safe_remove /etc/dyld_framework_paths.d
		safe_remove /etc/dyld_framework_paths
	fi
	if [ -d /etc/dyld_library_paths.d ]; then
		safe_remove /etc/dyld_library_paths.d
		safe_remove /etc/dyld_library_paths
	fi
	if [ -d /etc/pkg_config_paths.d ]; then
		safe_remove /etc/pkg_config_paths.d
		safe_remove /etc/pkg_config_paths
	fi
	if [ -d /etc/c_include_paths.d ]; then
		safe_remove /etc/c_include_paths.d
		safe_remove /etc/c_include_paths
	fi
}

# --- Tests ------------------------------------------------------------------

test_setup(){
	[ -d $HOME/.config/paths/c_include_paths.d ] &&
	[ -d /etc/c_include_paths.d ] &&
	[ -f $HOME/.config/paths/c_include_paths ] &&
	[ -f /etc/c_include_paths ] &&
	[ -d $HOME/.config/paths/dyld_fallback_framework_paths.d ] &&
	[ -d /etc/dyld_fallback_framework_paths.d ] &&
	[ -f $HOME/.config/paths/dyld_fallback_framework_paths ] &&
	[ -f /etc/dyld_fallback_framework_paths ] &&
	[ -d $HOME/.config/paths/dyld_fallback_library_paths.d ] &&
	[ -d /etc/dyld_fallback_library_paths.d ] &&
	[ -f $HOME/.config/paths/dyld_fallback_library_paths ] &&
	[ -f /etc/dyld_fallback_library_paths ] &&
	[ -d $HOME/.config/paths/dyld_framework_paths.d ] &&
	[ -d /etc/dyld_framework_paths.d ] &&
	[ -f $HOME/.config/paths/dyld_framework_paths ] &&
	[ -f /etc/dyld_framework_paths ] &&
	[ -d $HOME/.config/paths/dyld_library_paths.d ] &&
	[ -d /etc/dyld_library_paths.d ] &&
	[ -f $HOME/.config/paths/dyld_library_paths ] &&
	[ -f /etc/dyld_library_paths ] &&
	[ -d $HOME/.config/paths/manpaths.d ] &&
	[ -d /etc/manpaths.d ] &&
	[ -f $HOME/.config/paths/manpaths ] &&
	[ -f /etc/manpaths ] &&
	[ -d $HOME/.config/paths/pkg_config_paths.d ] &&
	[ -d /etc/pkg_config_paths.d ] &&
	[ -f $HOME/.config/paths/pkg_config_paths ] &&
	[ -f /etc/pkg_config_paths ] &&
	[ -d $HOME/.config/paths/paths.d ] &&
	[ -d /etc/paths.d ] &&
	[ -f $HOME/.config/paths/paths ]
}

# Function to get time in nanoseconds.
# Ruby is a hard dependency of this suite (it runs exe/path_helper), so it is
# present everywhere these tests run, unlike `date +%N` which is GNU-only --
# BSD/macOS and musl/busybox emit a literal "N". CLOCK_MONOTONIC is system-wide,
# so readings from two separate processes are safe to subtract, and it cannot be
# skewed by a clock adjustment mid-measurement.
get_time_ns() {
	ruby -e 'print Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)'
}

# test_a_path <description> <fixture> <argument>...
# Runs the executable and compares its output with a fixture, emitting one test
# point plus a timing comment. On failure the YAML block names the fixture and
# the arguments, and the diff, expected and actual output follow as comments.
test_a_path(){
	local description="$1"
	local output_file="$2"
	shift 2
	local actual=$(mktemp)
	local expected=$(mktemp)
	local difference=$(mktemp)
	local noise=$(mktemp)

	# Measured around the executable alone, not the comparison. Reported in
	# milliseconds; this includes the startup time of the ruby process that
	# takes the closing reading -- a constant offset of a few tens of
	# milliseconds, uniform across runs and platforms.
	local start=$(get_time_ns)
	"$EXECUTABLE" "${@}" > "$actual" 2> "$noise"
	local end=$(get_time_ns)

	# A run can succeed and still output to STDERR
	# For example, a line dropped for including a colon is
	# reported on stderr while the test may be about about stdout,
	# so anything on stderr is passed on as comments
	# to avoid hitting the TAP stream.
	# test_a_path_with_stderr does the assertion for that.
	if [ -s "$noise" ]; then
		tap_comment_file "stderr" "$noise"
	fi

	# Fixtures store the home directory as a {{HOME}} placeholder so that they
	# are not tied to the user the tests happen to run as. Any literal $HOME in
	# a fixture is left alone: that comes from the input files and is expected
	# in the output verbatim.
	sed "s|{{HOME}}|$HOME|g" "$PWD/spec/fixtures/results/${output_file}" > "$expected"

	if cmp -s "$expected" "$actual"; then
		tap_ok "$description"
	else
		cmp "$expected" "$actual" > "$difference" 2>&1
		tap_not_ok "$description"
		tap_yaml "output did not match the fixture" \
			"fixture: '$output_file'" \
			"arguments: '$*'"
		tap_comment_file "cmp" "$difference"
		tap_comment_file "expected" "$expected"
		tap_comment_file "actual" "$actual"
	fi

	tap_comment "Performance: $description took $(( (end - start) / 1000000 ))ms"

	rm -f "$actual" "$expected" "$difference" "$noise"
}

# test_a_path_with_stderr <description> <stdout fixture> <stderr fixture> <argument>...
# The other path tests leave stderr alone, as that is the normal run of things.
# However, a malformed line in an input file is an exception to this.
# It is dropped and a warning is provided, and the rest of the path is built.
# It is not a failure state.
# Both streams are compared to fixtures here, and the wording is identical
# in every implementation, so the stderr comparison is byte for byte like the
# stdout one.
test_a_path_with_stderr(){
	local description="$1"
	local output_file="$2"
	local error_file="$3"
	shift 3
	local actual=$(mktemp)
	local actual_err=$(mktemp)
	local expected=$(mktemp)
	local expected_err=$(mktemp)
	local difference=$(mktemp)
	local status

	"$EXECUTABLE" "${@}" > "$actual" 2> "$actual_err"
	status=$?

	if [ $status -eq 0 ]; then
		tap_ok "$description exits successfully"
	else
		tap_not_ok "$description exits successfully"
		tap_yaml "a dropped line is not a refusal, so the run must still succeed" \
			"arguments: '$*'" \
			"status: $status"
		tap_comment_file "stderr" "$actual_err"
	fi

	sed "s|{{HOME}}|$HOME|g" "$PWD/spec/fixtures/results/${output_file}" > "$expected"
	sed "s|{{HOME}}|$HOME|g" "$PWD/spec/fixtures/results/${error_file}" > "$expected_err"

	if cmp -s "$expected" "$actual"; then
		tap_ok "$description builds the expected path"
	else
		cmp "$expected" "$actual" > "$difference" 2>&1
		tap_not_ok "$description builds the expected path"
		tap_yaml "output did not match the fixture" \
			"fixture: '$output_file'" \
			"arguments: '$*'"
		tap_comment_file "cmp" "$difference"
		tap_comment_file "expected" "$expected"
		tap_comment_file "actual" "$actual"
	fi

	if cmp -s "$expected_err" "$actual_err"; then
		tap_ok "$description says the expected thing on stderr"
	else
		cmp "$expected_err" "$actual_err" > "$difference" 2>&1
		tap_not_ok "$description says the expected thing on stderr"
		tap_yaml "stderr did not match the fixture" \
			"fixture: '$error_file'" \
			"arguments: '$*'"
		tap_comment_file "cmp" "$difference"
		tap_comment_file "expected" "$expected_err"
		tap_comment_file "actual" "$actual_err"
	fi

	rm -f "$actual" "$actual_err" "$expected" "$expected_err" "$difference"
}

# The captured streams of the last run_expecting_failure, for the assertions
# that build on it. Held in globals because a shell function can only return a
# status, and the two files have to outlive the call that produced them.
failure_stdout=""
failure_stderr=""

# run_expecting_failure <description> <argument>...
# The executable is supposed to refuse these, so a zero exit status is the
# failure. Diagnosing a refusal means reading what it said, so stderr is
# captured for the caller and asserted on by the wrappers below; stdout has to
# stay empty either way, because an `export PATH=$(path_helper -p)` would
# otherwise swallow the complaint into PATH.
# The caller owns the captured files and must call end_expected_failure.
run_expecting_failure(){
	local description="$1"
	shift
	local status
	failure_stdout=$(mktemp)
	failure_stderr=$(mktemp)

	"$EXECUTABLE" "${@}" > "$failure_stdout" 2> "$failure_stderr"
	status=$?

	if [ $status -eq 0 ]; then
		tap_not_ok "$description exits with a non-zero status"
		tap_yaml "expected a non-zero exit status" "arguments: '$*'"
		tap_comment_file "stderr" "$failure_stderr"
	else
		tap_ok "$description exits with a non-zero status"
	fi

	if [ -s "$failure_stdout" ]; then
		tap_not_ok "$description writes nothing to stdout"
		tap_yaml "stdout carries the built path, so it must stay empty here" \
			"arguments: '$*'"
		tap_comment_file "stdout" "$failure_stdout"
	else
		tap_ok "$description writes nothing to stdout"
	fi
}

end_expected_failure(){
	rm -f "$failure_stdout" "$failure_stderr"
	failure_stdout=""
	failure_stderr=""
}

# expect_failure <description> <fixture> <argument>...
# A refusal whose wording is part of the contract: the message is the same in
# every implementation, so stderr is compared byte for byte with a fixture, the
# same way stdout is for the path tests.
expect_failure(){
	local description="$1"
	local output_file="$2"
	shift 2
	local expected=$(mktemp)
	local difference=$(mktemp)

	run_expecting_failure "$description" "${@}"

	sed "s|{{HOME}}|$HOME|g" "$PWD/spec/fixtures/results/${output_file}" > "$expected"

	if cmp -s "$expected" "$failure_stderr"; then
		tap_ok "$description explains itself on stderr"
	else
		cmp "$expected" "$failure_stderr" > "$difference" 2>&1
		tap_not_ok "$description explains itself on stderr"
		tap_yaml "stderr did not match the fixture" \
			"fixture: '$output_file'" \
			"arguments: '$*'"
		tap_comment_file "cmp" "$difference"
		tap_comment_file "expected" "$expected"
		tap_comment_file "actual" "$failure_stderr"
	fi

	end_expected_failure
	rm -f "$expected" "$difference"
}

# expect_failure_with_usage <description> <argument>...
# A refusal that answers with the whole help message instead of a one-line
# complaint. That text is not comparable across implementations -- see
# HELP_SWITCHES below -- so it gets the same coverage check the --help tests
# use rather than a fixture.
expect_failure_with_usage(){
	local description="$1"
	shift

	run_expecting_failure "$description" "${@}"
	assert_usage_text "$description" "$failure_stderr" "$*"
	end_expected_failure
}

# test_version <description> <argument>...
# --version is expected to print the version and nothing else, and to print it
# on stderr: stdout belongs to the path being built, so anything landing there
# would be swallowed by an `export PATH=$(path_helper -p)`. The version itself
# is only checked for its semver shape -- the number changes with every release,
# and each implementation carries its own copy of it.
test_version(){
	local description="$1"
	shift
	local out=$(mktemp)
	local err=$(mktemp)
	local status

	"$EXECUTABLE" "${@}" > "$out" 2> "$err"
	status=$?

	if [ $status -eq 0 ]; then
		tap_ok "$description exits successfully"
	else
		tap_not_ok "$description exits successfully"
		tap_yaml "expected an exit status of 0" \
			"arguments: '$*'" \
			"status: $status"
		tap_comment_file "stderr" "$err"
	fi

	if [ -s "$out" ]; then
		tap_not_ok "$description writes nothing to stdout"
		tap_yaml "stdout carries the built path, so it must stay empty here" \
			"arguments: '$*'"
		tap_comment_file "stdout" "$out"
	else
		tap_ok "$description writes nothing to stdout"
	fi

	if [ "$(wc -l < "$err")" -eq 1 ] &&
		 grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)*$' "$err"; then
		tap_ok "$description reports a semver version on stderr"
	else
		tap_not_ok "$description reports a semver version on stderr"
		tap_yaml "expected a single line of MAJOR.MINOR.PATCH" \
			"arguments: '$*'"
		tap_comment_file "stderr" "$err"
	fi

	rm -f "$out" "$err"
}

# The switches the help output is expected to document. Each is an extended
# regular expression rather than a literal because the same switch is not
# rendered identically by every implementation's option parser: Ruby's
# OptionParser collapses a negatable switch into `--[no-]etc` where Crystal's
# lists `--etc` and `--no-etc` on separate lines. Wording and column layout are
# not comparable across implementations at all, which is why this is a coverage
# check and not a fixture comparison.
HELP_SWITCHES='--path
--man
--dyld-fallback-fram
--dyld-fallback-lib
--dyld-fram
--dyld-lib
--c-include
--pc
--quiet
--debug
--setup
--dry-run
--(\[no-\])?etc
--(\[no-\])?lib
--(\[no-\])?config
--version
--help'

# test_help <description> <argument>...
# Help goes to stderr for the same reason the version does, and exits 0: asking
# for help is not an error, unlike being given no arguments at all.
test_help(){
	local description="$1"
	shift
	local out=$(mktemp)
	local err=$(mktemp)
	local status

	"$EXECUTABLE" "${@}" > "$out" 2> "$err"
	status=$?

	if [ $status -eq 0 ]; then
		tap_ok "$description exits successfully"
	else
		tap_not_ok "$description exits successfully"
		tap_yaml "expected an exit status of 0" \
			"arguments: '$*'" \
			"status: $status"
		tap_comment_file "stderr" "$err"
	fi

	if [ -s "$out" ]; then
		tap_not_ok "$description writes nothing to stdout"
		tap_yaml "stdout carries the built path, so it must stay empty here" \
			"arguments: '$*'"
		tap_comment_file "stdout" "$out"
	else
		tap_ok "$description writes nothing to stdout"
	fi

	assert_usage_text "$description" "$err" "$*"

	rm -f "$out" "$err"
}

# assert_usage_text <description> <file> <arguments>
# The help message, wherever it turns up: asked for with -h, or volunteered by
# a refusal that has nothing more specific to say.
assert_usage_text(){
	local description="$1"
	local err="$2"
	local arguments="$3"
	local missing=""

	if grep -Eq '^Usage: .*\[options\]' "$err"; then
		tap_ok "$description prints a usage line on stderr"
	else
		tap_not_ok "$description prints a usage line on stderr"
		tap_yaml "expected a line of the form 'Usage: ... [options]'" \
			"arguments: '$arguments'"
		tap_comment_file "stderr" "$err"
	fi

	for switch in $HELP_SWITCHES; do
		grep -Eq -- "$switch" "$err" || missing="$missing $switch"
	done

	if [ -z "$missing" ]; then
		tap_ok "$description documents every switch"
	else
		tap_not_ok "$description documents every switch"
		tap_yaml "the help output left some switches undocumented" \
			"arguments: '$arguments'" \
			"missing: '${missing# }'"
		tap_comment_file "stderr" "$err"
	fi
}

# test_expansion_under_home <description> <home> <argument> <expected>
# The fixture comparison bakes in the HOME the suite is running as, so a run
# under a different HOME cannot be pinned that way. This builds the expectation
# from the home it passes in and compares the two strings directly.
test_expansion_under_home(){
	local description="$1"
	local home="$2"
	local argument="$3"
	local expected="$4"
	local actual

	# The argument has to follow -p directly: it is the switch's own optional
	# argument, and a token sitting after the other switches would be a stray
	# positional instead.
	actual=$(HOME="$home" "$EXECUTABLE" --no-etc --no-config --no-lib -p "$argument" 2>/dev/null)

	if [ "$actual" = "$expected" ]; then
		tap_ok "$description"
	else
		tap_not_ok "$description"
		tap_yaml "the expansion did not follow HOME" \
			"home: '$home'" \
			"argument: '$argument'" \
			"expected: '$expected'" \
			"actual: '$actual'"
	fi
}

# --- Run --------------------------------------------------------------------

TMPDIR=$(mktemp -d)
cleanup

# Nothing has been set up yet, so a complete setup is the failure here.
if test_setup; then
	tap_not_ok "the paths are absent before setup runs"
	tap_yaml "found a set up path tree before --setup was run"
else
	tap_ok "the paths are absent before setup runs"
fi

"$EXECUTABLE" --setup --no-lib --quiet
cp -R spec/fixtures/moredirs/* ~/.config/paths

# Populate /etc/paths if it's empty and the source file exists
if [ ! -s /etc/paths ] && [ -f docker/assets/etc-paths ]; then
	cp docker/assets/etc-paths /etc/paths
fi

if test_setup; then
	tap_ok "setup creates the path directories and files"
else
	tap_not_ok "setup creates the path directories and files"
	tap_yaml "--setup did not create the full path tree"
fi

# A segment's directory may be a symlink -- a dotfile repo that keeps its
# fragments together and links them into place is the ordinary case -- and it
# has to be walked like a real directory rather than skipped. `Dir.exist?` and
# `Dir.exists?` both follow the link, so this pins that neither implementation
# grows a check that does not.
# /etc/paths.d is the one search directory the run leaves empty, so it is the
# one that can be replaced without disturbing what is already pinned. It is
# swapped only after the assertion above has had its look at what --setup made.
rm -rf /etc/paths.d
mkdir -p "$HOME/symlinked-paths.d"
cp -R spec/fixtures/linkeddir/* "$HOME/symlinked-paths.d"
ln -s "$HOME/symlinked-paths.d" /etc/paths.d

if [ -L /etc/paths.d ] && [ -d /etc/paths.d ]; then
	tap_ok "the etc search directory is a symlink to a real directory"
else
	tap_not_ok "the etc search directory is a symlink to a real directory"
	tap_yaml "the test could not put a symlinked directory in the search graph"
fi

# A fragment file may itself be a symlink, for the same dotfile-repo reason as
# the directory above, so one is linked into the config segment's paths.d. A
# second link is left dangling: `File.file?` is false for both a link to
# nothing and a link to a directory, which is what keeps an unreadable entry
# out of the path in either implementation.
mkdir -p "$HOME/symlinked-fragments"
cp -R spec/fixtures/linkedfile/* "$HOME/symlinked-fragments"
ln -s "$HOME/symlinked-fragments/paths-fragment" "$HOME/.config/paths/paths.d/15-symlinked-file"
ln -s "$HOME/symlinked-fragments/no-such-fragment" "$HOME/.config/paths/paths.d/16-dangling"

if [ -L "$HOME/.config/paths/paths.d/15-symlinked-file" ] &&
   [ -f "$HOME/.config/paths/paths.d/15-symlinked-file" ] &&
   [ -L "$HOME/.config/paths/paths.d/16-dangling" ] &&
   [ ! -e "$HOME/.config/paths/paths.d/16-dangling" ]; then
	tap_ok "paths.d holds a symlinked fragment file and a dangling one"
else
	tap_not_ok "paths.d holds a symlinked fragment file and a dangling one"
	tap_yaml "the test could not put symlinked files in the search graph"
fi

# Every kind of path is built twice: once plainly, and once under --debug.
# The plain run checks the path that gets exported; the --debug run checks the
# account of how it was arrived at -- the env var's name, the options it was
# parsed into, the search order, the directories and files each segment looked
# at, and which line came from which file, with duplicates marked. That report
# is the only view of the search that a user ever gets, so it is worth pinning
# for each env var and not just for PATH: the section names are derived from
# the env var name (MANPATH -> manpaths.d/manpaths), and it is the debug output
# that shows the derivation went the way it was supposed to.
#
# Note the four DYLD paths, as their names are so close to each other.
# DYLD_LIBRARY_PATH uses dyld_library_paths.
# DYLD_FALLBACK_LIBRARY_PATH uses dyld_fallback_library_paths. Same goes for FRAMEWORK.
# Previously, the fixtures had only the DYLD_LIBRARY_PATH 
# while the CLI actually used DYLD_FALLBACK_LIBRARY_PATH.`-l` read nothing and the
# expected output was an empty file. All now have their own input files.
test_a_path "path_spec" "path.txt" "-p"
test_a_path "debug_path_spec" "debug_path.txt" "-p" "--debug"
test_a_path "manpath_spec" "manpath.txt" "-m"
test_a_path "debug_manpath_spec" "debug_manpath.txt" "-m" "--debug"
test_a_path "c_include_spec" "c_include.txt" "-c"
test_a_path "debug_c_include_spec" "debug_c_include.txt" "-c" "--debug"
test_a_path "dyld-fallback-fram_spec" "dyld-fallback-fram.txt" "-f"
test_a_path "debug_dyld-fallback-fram_spec" "debug_dyld-fallback-fram.txt" "-f" "--debug"
test_a_path "dyld-fallback-lib_spec" "dyld-fallback-lib.txt" "-l"
test_a_path "debug_dyld-fallback-lib_spec" "debug_dyld-fallback-lib.txt" "-l" "--debug"
test_a_path "dyld-fram_spec" "dyld-fram.txt" "--dyld-fram"
test_a_path "debug_dyld-fram_spec" "debug_dyld-fram.txt" "--dyld-fram" "--debug"
test_a_path "dyld-lib_spec" "dyld-lib.txt" "--dyld-lib"
test_a_path "debug_dyld-lib_spec" "debug_dyld-lib.txt" "--dyld-lib" "--debug"
test_a_path "pkg_config_spec" "pkg_config.txt" "--pc"
test_a_path "debug_pkg_config_spec" "debug_pkg_config.txt" "--pc" "--debug"

# Each segment of the search order can be switched off independently, and the
# three switches are orthogonal, so every combination of them is covered here.
# The expected output is the concatenation of whichever segments survive, in
# search order: the fixtures copied into ~/.config/paths for `config`, and
# /etc/paths for `etc`. Turning them all off is a legitimate request for an
# empty path rather than an error.
#
# `lib` is the segment these tests run without: the suite sets up with
# --no-lib, and on a non-Mac ~/Library/Paths is off by default anyway, so
# --no-lib can only ever be a no-op here. It is still worth asserting that it
# is one -- silently removing a segment nobody asked about would be a bug --
# and that it does not disturb the other two switches when combined with them.
test_a_path "no-etc leaves the config segment" "path-no-etc.txt" "-p" "--no-etc"
test_a_path "no-config leaves the etc segment" "path-no-config.txt" "-p" "--no-config"
test_a_path "no-lib changes nothing" "path.txt" "-p" "--no-lib"
test_a_path "no-etc and no-config leave nothing" "path-no-segments.txt" "-p" "--no-etc" "--no-config"
test_a_path "no-etc and no-lib leave the config segment" "path-no-etc.txt" "-p" "--no-etc" "--no-lib"
test_a_path "no-config and no-lib leave the etc segment" "path-no-config.txt" "-p" "--no-config" "--no-lib"
test_a_path "all three leave nothing" "path-no-segments.txt" "-p" "--no-etc" "--no-config" "--no-lib"

# The same switches on another env var, to show the segment logic is a property
# of the search order and not of PATH: MANPATH's /etc file is created empty by
# --setup, so dropping the config segment leaves nothing at all behind.
test_a_path "no-etc leaves the config segment for manpaths" "manpath.txt" "-m" "--no-etc"
test_a_path "no-config leaves nothing for manpaths" "path-no-segments.txt" "-m" "--no-config"

expect_failure_with_usage "must provide an argument"
expect_failure "the kind of path must be declared" "error_no_kind.txt" "-q"

# The kind of path is the one argument the program cannot supply a default for,
# so every other switch is still missing it when it stands on its own: a mode
# switch (--debug), a switch that only says which segments to search (--no-etc,
# --config), and one that is only meaningful next to --setup (--dry-run). Each
# has to be refused with the same complaint rather than silently building PATH.
expect_failure "the kind of path is still missing after --debug" "error_no_kind.txt" "-d"
expect_failure "the kind of path is still missing after --no-etc" "error_no_kind.txt" "--no-etc"
expect_failure "the kind of path is still missing after --config" "error_no_kind.txt" "--config"
expect_failure "the kind of path is still missing after --dry-run" "error_no_kind.txt" "--dry-run"

# An unrecognised switch is refused rather than ignored, and the complaint names
# the switch so it is obvious which one was wrong. The second case follows a
# valid switch to show that a good switch earlier in the line does not excuse a
# bad one later, and that nothing built so far leaks onto stdout.
expect_failure "an unknown long option" "error_invalid_option.txt" "--bogus"
expect_failure "an unknown short option" "error_invalid_short_option.txt" "-q" "-z"

# The path switches take an *optional* argument, and the two option parsers
# would otherwise disagree about a `-`-prefixed token in that position: Ruby's
# refuses it, Crystal's takes it as the value unless it happens to be a
# registered flag. A switch is never a path, so both refuse it -- see
# PathHelper.path_argument in src/path_helper.cr.
expect_failure "an unknown short option after --path" "error_invalid_short_option.txt" "-p" "-z"
expect_failure "an unknown short option after --pc" "error_invalid_short_option.txt" "--pc" "-z"

test_version "--version" "--version"

test_help "-h" "-h"
test_help "--help" "--help"

# Edge cases in the input files.
# Empty files are skipped, as are blank lines. Adding `::`, would put
# the current working directory on PATH, which is a security problem.
# spec/fixtures/moredirs/paths.d/01-empty is that file, and it sorts
# first, so anything it leaked would show up at the very front of the path.
# The manpath tests also check this.
# debug_manpath.txt has files listed with no lines beneath them.
test_a_path "an empty input file adds no components" "path.txt" "-p"
test_a_path "an empty input file is still listed in the debug report" "debug_path.txt" "-p" "--debug"

# An empty component joins as `::` so must be dropped prior to the debug
# report
# A blank line must also be removed
# spec/fixtures/moredirs/paths.d/02-blank-lines has various blank lines,
# including whitespace-only ones.
test_a_path "blank lines add no components" "path.txt" "-p"
test_a_path "blank lines are absent from the debug report" "debug_path.txt" "-p" "--debug"

# A file's last line may or may not be terminated. Both readers chomp, so an
# unterminated last line still has to arrive as a component rather than being
# dropped or run onto the next file's first line, and a terminated one must not
# produce a phantom empty component after it.
# spec/fixtures/moredirs/paths.d/07-trailing-newline ends with a newline,
# 08-no-trailing-newline does not. (Files ending in *several* newlines are
# 02-blank-lines' business, above.)
test_a_path "a last line is read with or without a trailing newline" "path.txt" "-p"
test_a_path "both files read the same way in the debug report" "debug_path.txt" "-p" "--debug"

# The app must handle Windows line endings. A CRLF blank line must
# also still count as blank and not become an "\r".
# spec/fixtures/moredirs/paths.d/09-crlf is CRLF throughout.
test_a_path "CRLF line endings do not leak a carriage return" "path.txt" "-p"
test_a_path "CRLF lines are clean in the debug report" "debug_path.txt" "-p" "--debug"

# Path env vars like PATH, MANPATH etc do accept spaces, so path_helper accepts spaces.
# Nothing is stripped or collapsed, so a component arrives verbatim, and spaces never split
# items. The caller is still recommended to quote calls, e.g. `export PATH="$(path_helper -p)"`.
# spec/fixtures/moredirs/paths.d/11-spaces has the examples.
# Only a wholly blank line is dropped: a line that has a path in it keeps
# whatever whitespace surrounds that path, so `11-spaces`' last line arrives
# with its leading space intact.
test_a_path "spaces within a path are preserved" "path.txt" "-p"
test_a_path "spaces around a path are not stripped" "path.txt" "-p"
test_a_path "spaces within a path survive the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a path with spaces is appended verbatim" "path-spaces-appended.txt" "-p" "/opt/appended with spaces/bin:~/appended with spaces"

# Special characters (except colon)
# spec/fixtures/moredirs/paths.d/12-special-chars holds the examples.
test_a_path "special characters within a path are preserved" "path.txt" "-p"
test_a_path "special characters survive the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a path with special characters is appended verbatim" \
	"path-special-chars-appended.txt" "-p" '/opt/appended*glob?/bin:/opt/appended$(dollars)&{braces}/bin'

# Non-ASCII paths. A component is bytes to be passed through, not text to be
# interpreted, so nothing is transliterated, re-encoded or normalised on the way
# out. spec/fixtures/moredirs/paths.d/13-unicode holds the examples: Latin with
# an accent, CJK, Cyrillic, Greek behind a `~`, and an astral-plane emoji.
# Its first two lines are the same word spelled two ways -- NFC (one codepoint
# for the accented letter) and NFD (letter plus a combining accent). They render
# identically but are different byte sequences, so de-duplication must keep both
# rather than folding them together.
test_a_path "non-ASCII characters within a path are preserved" "path.txt" "-p"
test_a_path "non-ASCII characters survive the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a path with non-ASCII characters is appended verbatim" \
	"path-unicode-appended.txt" "-p" "/opt/appended/ünïcødé/bin:~/appended/漢字"

# Nothing is stat'ed. A component is a declaration of where to look, not a
# promise that anything is there, so a directory that does not exist is passed
# through like any other -- the same as Apple's path_helper, and what lets a
# fragment file be installed before the thing it points at.
# spec/fixtures/moredirs/paths.d/14-nonexistent holds the examples: an absent
# directory, one whose parent is absent too, one behind a `~`, one whose parent
# is real but whose leaf is not, and a path that exists but is a *file*
# (`/etc/paths`), which is not filtered out either.
test_a_path "a non-existent directory is still a component" "path.txt" "-p"
test_a_path "a non-existent directory is listed in the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a non-existent directory given as an argument is appended too" \
	"path-nonexistent-appended.txt" "-p" "/opt/appended-does-not-exist/bin:~/appended-does-not-exist"

# A symlinked search directory. /etc/paths.d is a symlink to
# $HOME/symlinked-paths.d for the whole run (see the setup above), so every
# path fixture already goes through it; these name the behaviour so a failure
# says what broke. The fragment behind the link is read like any other, in the
# etc segment and so behind everything the config segment found, and the debug
# report names it by the path it was reached through -- /etc/paths.d/01-linked,
# not the resolved target -- since it is the search graph being reported on.
test_a_path "a symlinked search directory is walked" "path.txt" "-p"
test_a_path "a symlinked search directory is reported by the path it was reached through" \
	"debug_path.txt" "-p" "--debug"

# A symlinked fragment file. 15-symlinked-file points at a real file and is
# read like any other; 16-dangling points at nothing and contributes no
# components. Both are linked in for the whole run (see the setup above).
# The debug report names each by its path in paths.d rather than by what it
# resolves to, and marks the dangling one "does not exist!" -- which is the
# same line a subdirectory would get, since what is being said is that there
# was no file there to read.
test_a_path "a symlinked fragment file is read" "path.txt" "-p"
test_a_path "a dangling symlink adds nothing and is marked in the debug report" \
	"debug_path.txt" "-p" "--debug"

# `$HOME` is not `~`. Only a literal tilde is expanded, so a fragment written
# with a shell variable in it arrives with that variable still in it -- and
# since the output of `$(path_helper -p)` is not re-scanned by the shell, that
# component reaches PATH as the four characters `$HOME`, not as a home
# directory. It is left alone rather than being dropped or expanded, which is
# what spec/fixtures/moredirs/paths.d/17-dollar-home pins: the bare form, the
# braced form, one embedded mid-path, and `$HOMEBREW`, which merely starts with
# the same letters and must not be mistaken for it.
# (10-keybase is the same behaviour arrived at honestly, from a real dotfile.)
test_a_path "a literal \$HOME is not expanded" "path.txt" "-p"
test_a_path "a literal \$HOME survives the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a literal \$HOME in an argument is appended verbatim" \
	"path-dollar-home-appended.txt" "-p" '$HOME/appended/bin'

# What `~` does expand to is whatever HOME says at the time -- both readers ask
# the environment (Ruby's Dir.home, Crystal's Path.home) rather than baking a
# home in or going to the passwd database. With every segment switched off the
# argument is the only thing in the output, so this compares the expansion on
# its own.
test_expansion_under_home "~ expands to the HOME in the environment" \
	"/tmp/not-a-real-home" "~/bin:~/sbin" "/tmp/not-a-real-home/bin:/tmp/not-a-real-home/sbin"

# Colons are not allowed within path declarations as they are separators for PATH et al
# When found, they are rejected but do not fail the whole run. That continues,
# and a message is put on STDERR.
# spec/fixtures/moredirs/paths.d/06-colons holds the examples.
test_a_path_with_stderr "a line containing a colon is dropped and reported" \
	"path.txt" "colons_warning.txt" "-p"
test_a_path_with_stderr "--quiet silences the report but still drops the line" \
	"path.txt" "no_warnings.txt" "-p" "-q"
test_a_path "a dropped line is absent from the debug report" "debug_path.txt" "-p" "--debug"

# Append mode. The path switches take an optional argument, and whatever is
# passed there is appended to the generated path -- pass the current value of
# the env var and the generated segments land in front of it, which is the
# whole point of `export PATH=$(path_helper -p "$PATH")`.
#
# Note that an argument is the *only* way to append: `-p` on its own builds a
# fresh path and ignores whatever PATH happens to hold, which is what the help
# text promises and what the path_spec case above already shows. The appended
# components keep the order they were given, go after everything the search
# found, are de-duplicated against it (first occurrence wins, so a component
# already generated stays where it was rather than moving to the end), and get
# the same `~` expansion as a line read from a file.
test_a_path "an empty argument builds a fresh path" "path.txt" "-p" ""
test_a_path "an argument is appended" "path-appended.txt" "-p" "/opt/appended/bin:~/appended:/usr/bin"
test_a_path "an argument of duplicates changes nothing" "path.txt" "-p" "/usr/bin:/bin"
test_a_path "an argument is appended for manpaths" "manpath-appended.txt" "-m" "/opt/appended/man:/opt/pkg/share/man"

tap_plan

cleanup

exit $tap_failed
