#!/bin/sh
#
# Runs spec/shell_spec.sh with line coverage switched on for the implementation
# under test, then writes a report. Every one of the suite's many runs of the
# executable is a separate process, so coverage is collected per process and
# merged afterwards.
#
# Usage: sh spec/lib/coverage/run.sh ruby|crystal <report dir> [test file]...
#
# Run it from the project root (the suite's fixtures are relative to it), as
# root, with PATH_HELPER_DOCKER_INSTANCE set: it is the destructive suite, and
# without the variable it only passes through the suite's SKIP.
#
#   ruby     PATH_HELPER_EXECUTABLE (default: ./exe/path_helper) is tested as
#            it is. spec/lib/coverage/ruby_coverage.rb is loaded into every
#            Ruby process through RUBYOPT and writes that run's counts on exit.
#            Needs nothing beyond the Ruby the suite already uses.
#   crystal  Builds a debug binary (the release build has no line table) from
#            the Crystal sources in PATH_HELPER_COVERAGE_SRC (default: the
#            working directory; it needs shard.yml and src/) and tests that,
#            each run under kcov (see docker/install-kcov.sh), which must be on
#            PATH. kcov traces with ptrace and turns off address randomisation,
#            which a container's default seccomp profile refuses; run the
#            container with `--security-opt seccomp=unconfined`.
#
# The report dir gets summary.md (also printed, as TAP comments, after the
# suite's own output) and: for Ruby, a SimpleCov-compatible .resultset.json and
# path_helper.txt, the source with hit counts in the margin; for Crystal, kcov's
# HTML, Cobertura and codecov output under kcov/.
#
# Coverage never changes what the executable prints or its exit status, so the
# suite's results are the same as a plain run's. The exit status is the suite's,
# or 1 if it passed but no report could be made. There is no threshold.
#
# Everything the executable touches lives in a world-readable work directory
# (PATH_HELPER_COVERAGE_WORK, default /tmp/path_helper-coverage) rather than
# under the project, because one edge case test copies the executable and runs
# the copy as *nobody*, who cannot read root's home.

language="$1"
report_dir="$2"
if [ $# -lt 2 ]; then
	echo "Usage: $0 ruby|crystal <report dir> [test file]..." >&2
	exit 2
fi
shift 2

SPEC_DIR=$(cd "$(dirname "$0")/../.." && pwd)
COVERAGE_DIR="$SPEC_DIR/lib/coverage"
WORK="${PATH_HELPER_COVERAGE_WORK:-/tmp/path_helper-coverage}"

# The suite reports the skip itself.
if [ -z "$PATH_HELPER_DOCKER_INSTANCE" ]; then
	exec "$SPEC_DIR/shell_spec.sh" "$@"
fi

bail(){
	echo "Bail out! $1"
	exit 1
}

rm -rf "$WORK"
mkdir -p "$WORK/raw" "$report_dir" || bail "cannot create $WORK or $report_dir"
chmod 755 "$WORK"
# Written to by every run, including the ones as *nobody*.
chmod 1777 "$WORK/raw"

case "$language" in
	ruby)
		executable="${PATH_HELPER_EXECUTABLE:-$PWD/exe/path_helper}"
		cp "$COVERAGE_DIR/ruby_coverage.rb" "$WORK/ruby_coverage.rb"
		chmod 644 "$WORK/ruby_coverage.rb"
		RUBYOPT="-r$WORK/ruby_coverage.rb${RUBYOPT:+ $RUBYOPT}"
		PATH_HELPER_COVERAGE_RAW="$WORK/raw"
		PATH_HELPER_EXECUTABLE="$executable"
		export RUBYOPT PATH_HELPER_COVERAGE_RAW PATH_HELPER_EXECUTABLE
		title="Ruby $(RUBYOPT='' ruby -e 'print RUBY_VERSION')"
		;;
	crystal)
		kcov=$(command -v kcov) || bail "kcov is not on PATH; see docker/install-kcov.sh"
		src="${PATH_HELPER_COVERAGE_SRC:-$PWD}"
		[ -f "$src/shard.yml" ] && [ -d "$src/src" ] || bail "no Crystal sources in $src"
		mkdir -p "$WORK/build" "$WORK/bin"
		cp -R "$src/src" "$src/shard.yml" "$WORK/build/"
		# A plain (non --release) build keeps the debug info and the line
		# table kcov maps addresses back to source lines with.
		crystal build --debug -o "$WORK/bin/path_helper" "$WORK/build/src/path_helper.cr" \
			> "$WORK/build.log" 2>&1 || {
			sed 's/^/# /' "$WORK/build.log"
			bail "the debug build of the Crystal implementation failed"
		}
		# Each user gets its own kcov output directory: kcov accumulates runs
		# into one, and *nobody* could not write into root's.
		cat > "$WORK/path_helper" <<-EOF
			#!/bin/sh
			out="$WORK/raw/\$(id -u)"
			mkdir -p "\$out" 2>/dev/null
			exec "$kcov" --include-path="$WORK/build/src" "\$out" "$WORK/bin/path_helper" "\$@"
		EOF
		chmod -R a+rX "$WORK"
		chmod 755 "$WORK/path_helper"
		PATH_HELPER_EXECUTABLE="$WORK/path_helper"
		export PATH_HELPER_EXECUTABLE
		title="Crystal $(crystal --version | sed -n '1s/^Crystal \([^ ]*\).*/\1/p')"
		;;
	*)
		echo "Usage: $0 ruby|crystal <report dir> [test file]..." >&2
		exit 2
		;;
esac

"$SPEC_DIR/shell_spec.sh" "$@"
status=$?

# The report, as TAP comments so the stream stays valid TAP.
report="$WORK/report.log"
case "$language" in
	ruby)
		RUBYOPT='' ruby "$COVERAGE_DIR/report.rb" ruby "$title" "$report_dir" \
			"$WORK/raw" "$PATH_HELPER_EXECUTABLE" "exe/path_helper" > "$report" 2>&1
		;;
	crystal)
		rm -rf "$report_dir/kcov"
		"$kcov" --merge "$report_dir/kcov" "$WORK"/raw/* > "$report" 2>&1 &&
		ruby "$COVERAGE_DIR/report.rb" kcov "$title" "$report_dir" \
			"$report_dir/kcov" "$WORK/build" >> "$report" 2>&1
		;;
esac
report_status=$?
sed 's/^/# /' "$report"
chmod -R a+rX "$report_dir" 2>/dev/null

if [ "$report_status" -ne 0 ]; then
	echo "# The coverage report could not be made."
	[ "$status" -eq 0 ] && status=1
fi

exit "$status"
