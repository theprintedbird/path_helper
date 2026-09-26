# Sourced by spec/shell_spec.sh after setup_test.sh, whose search graph these
# fixtures describe.

# Every kind of path is built twice: once plainly, and once under --debug.
# The plain run checks the path for export; the --debug run checks:
# - the env var's name
# - the options resulting from parse
# - the search order
# - the directories and files each segment looked at
# - which line came from which file, with duplicates marked.
#
# Note the four DYLD paths, as their names are so close to each other.
# DYLD_LIBRARY_PATH uses dyld_library_paths.
# DYLD_FALLBACK_LIBRARY_PATH uses dyld_fallback_library_paths. Same goes for FRAMEWORK.
# Previously, the fixtures had only the DYLD_LIBRARY_PATH 
# while the CLI actually used DYLD_FALLBACK_LIBRARY_PATH.`-l` read nothing and the
# expected output was an empty file. All now have their own input files.
# The other segment (see OTHER_SEGMENT in spec/shell_spec.sh) is populated but
# switched off by default, so none of its lines should appear in these.
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

# The DEBUG env var turns on the debug report too, whatever its value, as if
# --debug had followed the other switches -- so the options in the report are
# the same, and so is the rest of it.
test_a_path_with_env "DEBUG in the environment gives the debug report" \
	"debug_path.txt" "DEBUG=1" "-p"

# The debug report is coloured on a terminal, and only there.
test_colour_on_a_terminal "the debug report is coloured on a terminal"

# Each segment of the search order can be switched off independently, and the
# three switches are independent, so all combinations are covered here.
# The expected output is the concatenation of whichever segments remain, in
# search order:
# - the fixtures copied into the user segment
# - /etc/paths
# Turning them all off is allowed.
#
# The user segment is searched by default:
# - `config` (~/.config/paths) on Linux
# - `lib` (~/Library/Paths) on macOS
# See USER_SEGMENT in spec/shell_spec.sh.
# The other segment is populated by setup_test.sh but off by default, so
# switching it off leaves the default output; switching it on is tested below.
# The segments hold the same lines on every platform, so these plain fixtures
# are shared; `path-no-user.txt` is the etc segment on its own.
test_a_path "no-etc leaves the $USER_SEGMENT segment" "path-no-etc.txt" "-p" "--no-etc"
test_a_path "no-$USER_SEGMENT leaves the etc segment" "path-no-user.txt" "-p" "--no-$USER_SEGMENT"
test_a_path "no-$OTHER_SEGMENT leaves the default, which already omits it" "path.txt" "-p" "--no-$OTHER_SEGMENT"
test_a_path "no-etc and no-$USER_SEGMENT leave nothing" "path-no-segments.txt" "-p" "--no-etc" "--no-$USER_SEGMENT"
test_a_path "no-etc and no-$OTHER_SEGMENT leave the $USER_SEGMENT segment" "path-no-etc.txt" "-p" "--no-etc" "--no-$OTHER_SEGMENT"
test_a_path "no-$USER_SEGMENT and no-$OTHER_SEGMENT leave the etc segment" "path-no-user.txt" "-p" "--no-$USER_SEGMENT" "--no-$OTHER_SEGMENT"
test_a_path "all three leave nothing" "path-no-segments.txt" "-p" "--no-etc" "--no-config" "--no-lib"

# etc is searched by default, so naming it changes nothing, and it undoes an
# earlier --no-etc as the other segments' switches do. Crystal's parser has a
# handler of its own for --etc, where Ruby's has one --[no-]etc switch.
test_a_path "etc, on by default, changes nothing" "path.txt" "-p" "--etc"
test_a_path "no-etc then etc leaves it on" "path.txt" "-p" "--no-etc" "--etc"

# The same switches on another env var, to show the segment logic is a property
# of the search order and not of PATH.
# MANPATH's /etc file is created empty by --setup, dropping the user segment
# leaves nothing at all behind.
test_a_path "no-etc leaves the $USER_SEGMENT segment for manpaths" "manpath.txt" "-m" "--no-etc"
test_a_path "no-$USER_SEGMENT leaves nothing for manpaths" "path-no-segments.txt" "-m" "--no-$USER_SEGMENT"

# The second segment of the default order, and the switch that enables it.
# Each platform searches [user, other, etc] once --$OTHER_SEGMENT is given:
# - Linux: [:config, :lib, :etc], so --lib adds ~/Library/Paths
# - macOS: [:lib, :config, :etc], so --config adds ~/.config/paths
# The other segment is always second, so the plain outputs are the same on
# both and the fixtures are shared. Its lines land between the user segment's
# and /etc's, and the two it shares with the user segment (/opt/pkg/bin and
# /usr/local/bin) are dropped there, as the user segment got them first.
# Naming the user segment, which is on anyway, changes nothing.
test_a_path "$USER_SEGMENT, on by default, changes nothing" "path.txt" "-p" "--$USER_SEGMENT"
test_a_path "$OTHER_SEGMENT adds the $OTHER_SEGMENT segment between $USER_SEGMENT and etc" \
	"path-with-other.txt" "-p" "--$OTHER_SEGMENT"
# The debug report names the directories, so it has a Darwin copy, in which
# ~/Library/Paths is first and ~/.config/paths second.
test_a_path "the debug report searches $USER_SEGMENT, $OTHER_SEGMENT, then etc" \
	"debug_path_with_other.txt" "-p" "--$OTHER_SEGMENT" "--debug"
test_a_path "$OTHER_SEGMENT adds the $OTHER_SEGMENT segment for manpaths" \
	"manpath-with-other.txt" "-m" "--$OTHER_SEGMENT"

# A switch and its negation: both parsers let the last one win.
test_a_path "$OTHER_SEGMENT then no-$OTHER_SEGMENT leaves it off" "path.txt" "-p" "--$OTHER_SEGMENT" "--no-$OTHER_SEGMENT"
test_a_path "no-$OTHER_SEGMENT then $OTHER_SEGMENT leaves it on" "path-with-other.txt" "-p" "--no-$OTHER_SEGMENT" "--$OTHER_SEGMENT"

# The other segment without the user segment in front of it. Now it is the one
# to get /opt/pkg/bin and /usr/local/bin first, and /etc/paths' /usr/local/bin
# is the duplicate -- the other segment is still searched before etc.
test_a_path "$OTHER_SEGMENT and no-$USER_SEGMENT leave $OTHER_SEGMENT then etc" \
	"path-other-no-user.txt" "-p" "--$OTHER_SEGMENT" "--no-$USER_SEGMENT"
test_a_path "the debug report marks the etc duplicate of a $OTHER_SEGMENT line" \
	"debug_path_other_no_user.txt" "-p" "--$OTHER_SEGMENT" "--no-$USER_SEGMENT" "--debug"
test_a_path "$OTHER_SEGMENT with no-$USER_SEGMENT and no-etc leaves only $OTHER_SEGMENT" \
	"path-other-only.txt" "-p" "--$OTHER_SEGMENT" "--no-$USER_SEGMENT" "--no-etc"

# `--no-lib` against a real ~/Library/Paths is covered on both platforms by the
# tests above, through the segment variables:
# - macOS: ~/Library/Paths is the user segment, so every --no-$USER_SEGMENT test
#   is --no-lib removing its populated lines.
# - Linux: ~/Library/Paths is the other segment. The default output has none of
#   its lines anyway, so it is `--lib --no-lib` (the last-one-wins test) that
#   shows --no-lib switching off a populated ~/Library/Paths, and
#   `--no-lib --lib` that shows the same tree is otherwise there to be found.

# Append mode.
# The path switches take an optional argument that is appended to the generated path.
# Passing the current value of the env var (e.g. `$PATH`) and the generated segments precede it.
# For example `export PATH=$(path_helper -p "$PATH")`.
#
# Note that an argument is the *only* way to append: `-p` on its own builds a
# fresh path and ignores whatever PATH happens to hold. Appended
# components retain the order they were given, are appended to search components,
# and are de-duplicated against it (first occurrence wins).
test_a_path "an empty argument builds a fresh path" "path.txt" "-p" ""
test_a_path "an argument is appended" "path-appended.txt" "-p" "/opt/appended/bin:~/appended:/usr/bin"
test_a_path "an argument of duplicates changes nothing" "path.txt" "-p" "/usr/bin:/bin"
test_a_path "an argument is appended for manpaths" "manpath-appended.txt" "-m" "/opt/appended/man:/opt/pkg/share/man"

test_a_path "the debug report lists( an argument's components after the search" \
	"debug_path_appended.txt" "-p" "/opt/appended/bin:~/appended:/usr/bin" "--debug"
