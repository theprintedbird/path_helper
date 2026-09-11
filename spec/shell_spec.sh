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
# second link is left dangling, so there is an entry with nothing behind it.
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

# Not everything in a paths.d is a file. A subdirectory and a named pipe are
# made here rather than kept as fixtures, since git keeps neither an empty
# directory nor a pipe. Neither can be read as a list of paths -- and reading a
# pipe would block until something wrote to it -- so both are passed over, and
# the debug report says which kind of thing each one is.
mkdir "$HOME/.config/paths/paths.d/21-subdirectory"
mkfifo "$HOME/.config/paths/paths.d/22-fifo"

if [ -d "$HOME/.config/paths/paths.d/21-subdirectory" ] &&
   [ -p "$HOME/.config/paths/paths.d/22-fifo" ]; then
	tap_ok "paths.d holds a subdirectory and a named pipe"
else
	tap_not_ok "paths.d holds a subdirectory and a named pipe"
	tap_yaml "the test could not put a subdirectory and a pipe in the search graph"
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

# A path switch's argument is optional and only the token straight after it, so
# a path written after another switch is not the argument to append -- it is
# left over. Ignoring it would quietly build the path without it, so it is
# refused, wherever it sits, and after `--` too.
expect_failure "a path after another switch" "error_unexpected_argument.txt" "-p" "--no-etc" "/some/path"
expect_failure "a path before the switches" "error_unexpected_argument.txt" "/some/path" "-p"
expect_failure "a second path after the argument" "error_unexpected_argument.txt" "-p" "/other/path" "/some/path"
expect_failure "a path after --setup" "error_unexpected_argument.txt" "--setup" "--dry-run" "/some/path"
expect_failure "a path after --" "error_unexpected_argument.txt" "-p" "--" "/some/path"

# `--` straight after a path switch ends the options rather than becoming the
# argument, so on its own it leaves nothing over and builds a fresh path. Ruby's
# parser does that itself; Crystal's takes `--` as the value and has to be
# stopped -- see PathHelper.path_argument in src/path_helper.cr.
test_a_path "-- after a path switch builds a fresh path" "path.txt" "-p" "--"

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

# Non-ASCII paths.
# spec/fixtures/moredirs/paths.d/13-unicode has the examples.
test_a_path "non-ASCII characters within a path are preserved" "path.txt" "-p"
test_a_path "non-ASCII characters survive the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a path with non-ASCII characters is appended verbatim" \
	"path-unicode-appended.txt" "-p" "/opt/appended/ünïcødé/bin:~/appended/漢字"

# spec/fixtures/moredirs/paths.d/14-nonexistent has the examples.
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
# resolves to, and marks the dangling one "does not exist!".
test_a_path "a symlinked fragment file is read" "path.txt" "-p"
test_a_path "a dangling symlink adds nothing and is marked in the debug report" \
	"debug_path.txt" "-p" "--debug"

# An entry in paths.d that is there but is not a readable file is not reported
# as missing: the report says what it found, so a subdirectory is marked "is a
# directory!" and a named pipe, which is neither a file nor a directory, "is
# not a regular file!". Both are made in the setup above.
test_a_path "a subdirectory and a named pipe in paths.d add nothing" "path.txt" "-p"
test_a_path "a subdirectory and a named pipe are marked for what they are in the debug report" \
	"debug_path.txt" "-p" "--debug"

# A regular file that cannot be read is passed over like the entries above,
# rather than taking the whole run down with it -- a fragment with the wrong
# mode would otherwise leave a login shell with no PATH at all. The debug report
# marks it "is not readable!". See test_unreadable_fragment for why this runs
# as nobody.
test_unreadable_fragment "an unreadable fragment adds nothing" \
	"unreadable_path.txt" "-p" "--no-etc"
test_unreadable_fragment "an unreadable fragment is marked in the debug report" \
	"debug_unreadable.txt" "-p" "--no-etc" "--debug"

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

# `~` is only replaced when it is the whole component or is followed by a `/`.
# Any other `~` is part of a name and is left alone, so a directory with a tilde in
# survives intact.
# The debug report shows the lines as they were read.
test_a_path "a tilde is expanded only at the front of a component" "path.txt" "-p"
test_a_path "the debug report shows tildes unexpanded" "debug_path.txt" "-p" "--debug"
test_a_path "a tilde in an argument is expanded the same way" \
	"path-tilde-appended.txt" "-p" "~/appended/bin:/opt/app~ended/bin"

# The same component named in two different files. First occurrence wins and
# keeps its place, so what matters is which file was read first -- and that is
# the search order, which is the whole reason this program exists: a user's
# fragment lands in front of the system's rather than being ignored as a
# repeat of it.
# spec/fixtures/moredirs/paths.d/19-dupes-across-files names three components
# that already appear elsewhere, one from each direction:
#   /usr/local/bin  is in /etc/paths, a later segment, so this copy wins and
#                   the /etc/paths one is the duplicate;
#   /opt/local/sbin is in ~/.config/paths/paths, the same segment's plain file,
#                   which is read after the directory, so this copy wins too;
#   /opt/pkg/bin    is already in 04-llvm and 05-pkgsrc, earlier in the same
#                   directory, so here it is the duplicate.
# The debug report marks whichever occurrence lost with ✗, which is the only
# place the losing ones are visible at all -- the path itself just has the one.
test_a_path "a component repeated across files appears once, at its first occurrence" \
	"path.txt" "-p"
test_a_path "the debug report marks the losing occurrence whichever file it is in" \
	"debug_path.txt" "-p" "--debug"

# The same component named twice in the one file. There is nothing special
# about it -- `all_lines` is a set either way -- but a fragment file that has
# grown a repeat is much more common than two files agreeing, so it is worth
# its own case. spec/fixtures/moredirs/paths.d/20-dupes-in-file repeats one
# component immediately, repeats it again further down with another component
# in between, and repeats that second one too.
# Its last line is `/opt/dupe/bin/`, the first component with a trailing
# slash. That is a different string, so it is a different component and both
# survive: the comparison is on the text of the line, not on the directory it
# would resolve to.
test_a_path "a component repeated within a file appears once" "path.txt" "-p"
test_a_path "every repeat within a file is marked in the debug report" \
	"debug_path.txt" "-p" "--debug"

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

# The debug report accounts for an argument too. It is not a file, so it is not
# checked for being one: it comes last, under the name "current path", with
# each component listed as it was given -- `~` unexpanded, like a line read
# from a file -- and one the search already found marked as the duplicate.
test_a_path "the debug report lists an argument's components after the search" \
	"debug_path_appended.txt" "-p" "/opt/appended/bin:~/appended:/usr/bin" "--debug"

tap_plan

cleanup

exit $tap_failed
