# Common functions for spec/shell_spec.sh, which sources this file.
#
# Nothing here runs anything: it defines the TAP reporting, the cleanup of the
# destructive parts of a run, and the assertions the tests are written with.
# The functions expect EXECUTABLE to name the implementation under test, and
# the fixtures are found relative to the working directory, so the suite is run
# from the project root.

# --- TAP output -------------------------------------------------------------

tap_count=0
tap_failed=0

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

# --- Cleanup ----------------------------------------------------------------

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
	# The target of the /etc/paths.d symlink (see the run in shell_spec.sh).
	# /etc/paths.d itself is removed with the rest of /etc, and `rm -rf` on a
	# symlink takes the link rather than what it points at, so the target has to
	# be named separately.
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

# --- Assertions -------------------------------------------------------------

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

# test_unreadable_fragment <description> <fixture> <argument>...
# The suite runs as root, and root can read a file whatever its mode, so an
# unreadable fragment can only be seen by running as somebody else. The run is
# made as nobody, under a HOME of its own whose paths.d holds one readable
# fragment and one that nobody may read. /root is closed to nobody, so the
# executable is copied into that HOME, and the run starts from inside it
# because the Crystal runtime stats the working directory as it starts up.
# Fixtures store that HOME as {{HOME}}, as the other path fixtures do.
test_unreadable_fragment(){
	local description="$1"
	local output_file="$2"
	shift 2
	local home=$(mktemp -d)
	local actual=$(mktemp)
	local expected=$(mktemp)
	local difference=$(mktemp)
	local noise=$(mktemp)

	mkdir -p "$home/.config/paths/paths.d"
	printf '/opt/readable/bin\n' > "$home/.config/paths/paths.d/01-readable"
	printf '/opt/unreadable/bin\n' > "$home/.config/paths/paths.d/02-unreadable"
	cp "$EXECUTABLE" "$home/path_helper"
	chmod -R a+rX "$home"
	chmod 000 "$home/.config/paths/paths.d/02-unreadable"

	su -s /bin/sh nobody -c \
		"cd '$home' && HOME='$home' PATH='$PATH' ./path_helper $*" > "$actual" 2> "$noise"

	if [ -s "$noise" ]; then
		tap_comment_file "stderr" "$noise"
	fi

	sed "s|{{HOME}}|$home|g" "$PWD/spec/fixtures/results/${output_file}" > "$expected"

	if cmp -s "$expected" "$actual"; then
		tap_ok "$description"
	else
		cmp "$expected" "$actual" > "$difference" 2>&1
		tap_not_ok "$description"
		tap_yaml "output did not match the fixture" \
			"fixture: '$output_file'" \
			"arguments: '$*'" \
			"user: 'nobody'"
		tap_comment_file "cmp" "$difference"
		tap_comment_file "expected" "$expected"
		tap_comment_file "actual" "$actual"
	fi

	rm -rf "$home"
	rm -f "$actual" "$expected" "$difference" "$noise"
}
