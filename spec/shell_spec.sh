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

cleanup(){
	if [ -d "$HOME/Library/Paths" ]; then
		rm -rf "$HOME/Library/Paths"
	fi
	if [ -d "$HOME/.config/paths" ]; then
		rm -rf "$HOME/.config/paths"
	fi
	if [ -d /etc/paths.d ]; then
		rm -rf /etc/paths.d
		rm /etc/paths
	fi
	if [ -d /etc/manpaths.d ]; then
		rm -rf /etc/manpaths.d
		rm /etc/manpaths
	fi
	if [ -d /etc/dyld_fallback_framework_paths.d ]; then
		rm -rf /etc/dyld_fallback_framework_paths.d
		rm /etc/dyld_fallback_framework_paths
	fi
	if [ -d /etc/dyld_fallback_library_paths.d ]; then
		rm -rf /etc/dyld_fallback_library_paths.d
		rm /etc/dyld_fallback_library_paths
	fi
	if [ -d /etc/pkg_config_paths.d ]; then
		rm -rf /etc/pkg_config_paths.d
		rm /etc/pkg_config_paths
	fi
	if [ -d /etc/c_include_paths.d ]; then
		rm -rf /etc/c_include_paths.d
		rm /etc/c_include_paths
	fi
}

test_a_path(){
	local output_file="$1"
	shift
	local tmpfile=$(mktemp)
	/usr/local/bin/ruby "$PWD/exe/path_helper" "${@}" > "$tmpfile"
	result="$PWD/spec/fixtures/results/${output_file}"
	cmp -s "$result" "$tmpfile"
}

test_setup(){
	[ -d /root/.config/paths/c_include_paths.d ] &&
	[ -d /etc/c_include_paths.d ] &&
	[ -f /root/.config/paths/c_include_paths ] &&
	[ -f /etc/c_include_paths ] &&
	[ -d /root/.config/paths/dyld_fallback_framework_paths.d ] &&
	[ -d /etc/dyld_fallback_framework_paths.d ] &&
	[ -f /root/.config/paths/dyld_fallback_framework_paths ] &&
	[ -f /etc/dyld_fallback_framework_paths ] &&
	[ -d /root/.config/paths/dyld_fallback_library_paths.d ] &&
	[ -d /etc/dyld_fallback_library_paths.d ] &&
	[ -f /root/.config/paths/dyld_fallback_library_paths ] &&
	[ -f /etc/dyld_fallback_library_paths ] &&
	[ -d /root/.config/paths/manpaths.d ] &&
	[ -d /etc/manpaths.d ] &&
	[ -f /root/.config/paths/manpaths ] &&
	[ -f /etc/manpaths ] &&
	[ -d /root/.config/paths/pkg_config_paths.d ] &&
	[ -d /etc/pkg_config_paths.d ] &&
	[ -f /root/.config/paths/pkg_config_paths ] &&
	[ -f /etc/pkg_config_paths ] &&
	[ -d /root/.config/paths/paths.d ] &&
	[ -d /etc/paths.d ] &&
	[ -f /root/.config/paths/paths ] &&
	[ -f /etc/paths ]
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

./exe/path_helper --setup --no-lib 2>&1 > /dev/null
cp -R spec/fixtures/moredirs/* ~/.config/paths

# This should pass now because the setup has been run
if ! test_setup; then
	PASS=1
	failures="${failures:+"$failures:"}setup_spec 2"
fi


if ! test_a_path "path.txt" "-p"; then
	PASS=1
	failures="${failures:+"$failures:"}path_spec"
fi

if ! test_a_path "debug_path.txt" "-p" "--debug"; then
	PASS=1
	failures="${failures:+"$failures:"}debug_path_spec"
fi

if ! test_a_path "manpath.txt" "-m"; then
	PASS=1
	failures="${failures:+"$failures:"}manpath_spec"
fi

if ! test_a_path "c_include.txt" "-c"; then
	PASS=1
	failures="${failures:+"$failures:"}c_include_spec"
fi

if ! test_a_path "dyld-fram.txt" "-f"; then
	PASS=1
	failures="${failures:+"$failures:"}dyld-fram_spec"
fi

if ! test_a_path "dyld-lib.txt" "-l"; then
	PASS=1
	failures="${failures:+"$failures:"}dyld-lib_spec"
fi

if ! test_a_path "pkg_config.txt" "--pc"; then
	PASS=1
	failures="${failures:+"$failures:"}pkg_config_spec"
fi

if ! test_a_path "debug_pkg_config.txt" "--pc" "--debug"; then
	PASS=1
	failures="${failures:+"$failures:"}pkg_config_spec"
fi

if [ $PASS -eq 0 ]; then
	echo Passed!
else
	echo "Failure :'("
	echo $failures | awk -F: '{for(i=1; i<=NF; i++) print "failed: "$i}'
fi

cleanup

return $PASS