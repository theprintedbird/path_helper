#!/bin/sh

PASS=0

trap cleanup 1 2 3 6

if [ -z "$PATH_HELPER_DOCKER_INSTANCE" ]; then
	echo "These tests are destructive"
	echo "which is why there is a Docker setup for them."
	echo "If you really want to run them"
	echo "then you need to set the PATH_HELPER_DOCKER_INSTANCE."
	echo "If it is empty this will not run."
	echo "Caveat emptor."
	exit 0;
fi

results=$(mktemp)

cleanup(){
	handle_error() {
		echo "Error: $1" >&2
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
	if [ -d /etc/pkg_config_paths.d ]; then
		safe_remove /etc/pkg_config_paths.d
		safe_remove /etc/pkg_config_paths
	fi
	if [ -d /etc/c_include_paths.d ]; then
		safe_remove /etc/c_include_paths.d
		safe_remove /etc/c_include_paths
	fi
}

test_a_path(){
	local test_name="$1"
	local output_file="$2"
	shift
	shift
	local actual=$(mktemp)

	ruby "$PWD/exe/path_helper" "${@}" > "$actual"

	local expected="$PWD/spec/fixtures/results/${output_file}"

	if ! cmp -s "$expected" "$actual"; then
		printf "$test_name:" >> "$results"
		cmp "$expected" "$actual" >> "$results"
		printf '\n\n---expected---\n\n' | cat - "$expected" >> "$results"
		printf '\n\n---actual---\n\n' | cat - "$actual" >> "$results"
		printf '\n\n------\n\n' >> "$results"
		return 1
	fi
	return 0
}

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

# Function to get time in nanoseconds
get_time_ns() {
    date +%s%N
}

# Function to run a baseline operation
baseline_operation() {
	i=0
	while [ $i -lt 1000000 ]; do
		: # No-op
		i=$((i + 1))
	done
}

measure_baseline() {
	local start=$(get_time_ns)
	baseline_operation
	local end=$(get_time_ns)
	echo $((end - start))
}

# Global variable to store baseline duration
BASELINE_DURATION=$(measure_baseline)

# Function to measure relative time
test_a_path_with_time() {
	local test_name="$1"

	# Measure test_a_path
	local test_start=$(get_time_ns)
	test_a_path "$@"
	local test_result=$?
	local test_end=$(get_time_ns)
	local test_duration=$((test_end - test_start))

	# Calculate relative time using global BASELINE_DURATION
	local relative_time=$(echo "scale=2; $test_duration / $BASELINE_DURATION" | bc)

	echo "Performance: $test_name took ${relative_time}x baseline time"

	return $test_result
}


TMPDIR=$(mktemp -d)
cleanup

failures=""

# This should fail the first time as there are no dirs/files
# Hence, a pass is a fail ;-)
if test_setup; then
	PASS=1
	failures="${failures:+"$failures:"}setup_spec 1"
fi

"$PWD/exe/path_helper" --setup --no-lib --quiet
cp -R spec/fixtures/moredirs/* ~/.config/paths
# Populate /etc/paths if it's empty and the source file exists
if [ ! -s /etc/paths ] && [ -f docker/assets/etc-paths ]; then
	cp docker/assets/etc-paths /etc/paths
fi

# This should pass now because the setup has been run
if ! test_setup; then
	PASS=1
	failures="${failures:+"$failures:"}setup_spec 2"
fi


if ! test_a_path_with_time "path_spec" "path.txt" "-p"; then
	PASS=1
	failures="${failures:+"$failures:"}path_spec"
fi

if ! test_a_path_with_time "debug_path_spec" "debug_path.txt" "-p" "--debug"; then
	PASS=1
	failures="${failures:+"$failures:"}debug_path_spec"
fi

if ! test_a_path_with_time "manpath_spec" "manpath.txt" "-m"; then
	PASS=1
	failures="${failures:+"$failures:"}manpath_spec"
fi

if ! test_a_path_with_time "c_include_spec" "c_include.txt" "-c"; then
	PASS=1
	failures="${failures:+"$failures:"}c_include_spec"
fi

if ! test_a_path_with_time "dyld-fram_spec" "dyld-fram.txt" "-f"; then
	PASS=1
	failures="${failures:+"$failures:"}dyld-fram_spec"
fi

if ! test_a_path_with_time "dyld-lib_spec" "dyld-lib.txt" "-l"; then
	PASS=1
	failures="${failures:+"$failures:"}dyld-lib_spec"
fi

if ! test_a_path_with_time "pkg_config_spec" "pkg_config.txt" "--pc"; then
	PASS=1
	failures="${failures:+"$failures:"}pkg_config_spec"
fi

if ! test_a_path_with_time "pkg_config_spec" "debug_pkg_config.txt" "--pc" "--debug"; then
	PASS=1
	failures="${failures:+"$failures:"}pkg_config_spec"
fi

# This should not be okay, therefore it should be a fail if
# running it seems okay.
if ruby "$PWD/exe/path_helper" 2>/dev/null; then
	PASS=1
	failures="${failures:+"$failures:"}must provide an argument"
fi

# This should not be okay, therefore it should be a fail if
# running it seems okay.
if ruby "$PWD/exe/path_helper" -q 2>/dev/null; then
	PASS=1
	failures="${failures:+"$failures:"}the kind of path must be declared"
fi

# With pre-existing path
if ! test_a_path_with_time "path_with_path_spec" "path-with-path.txt" "-p"; then
	PASS=1
	failures="${failures:+"$failures:"}path_spec"
fi


if [ $PASS -eq 0 ]; then
	echo Passed!
else
	echo "Failure :'("
	echo $failures | awk -F: '{for(i=1; i<=NF; i++) print "failed: "$i}'
	echo "More info..."
	cat $results
fi

cleanup

exit $PASS

