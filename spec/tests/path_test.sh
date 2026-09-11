# Building each kind of path: plainly and under --debug, with segments of the
# search order switched off, and with an argument appended.
#
# Sourced by spec/shell_spec.sh after setup_test.sh, whose search graph these
# fixtures describe.

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

# The debug report accounts for an argument too. It is not a file, so it is not
# checked for being one: it comes last, under the name "current path", with
# each component listed as it was given -- `~` unexpanded, like a line read
# from a file -- and one the search already found marked as the duplicate.
test_a_path "the debug report lists an argument's components after the search" \
	"debug_path_appended.txt" "-p" "/opt/appended/bin:~/appended:/usr/bin" "--debug"
