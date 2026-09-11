# Awkward input files and arguments: empty and blank lines, line endings,
# spaces, special and non-ASCII characters, symlinks, entries that are not
# readable files, $HOME and ~, duplicates, and colons.
#
# Sourced by spec/shell_spec.sh after setup_test.sh, which lays out most of the
# awkward entries these read.

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
# $HOME/symlinked-paths.d for the whole run (see setup_test.sh), so every
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
# components. Both are linked in for the whole run (see setup_test.sh).
# The debug report names each by its path in paths.d rather than by what it
# resolves to, and marks the dangling one "does not exist!".
test_a_path "a symlinked fragment file is read" "path.txt" "-p"
test_a_path "a dangling symlink adds nothing and is marked in the debug report" \
	"debug_path.txt" "-p" "--debug"

# An entry in paths.d that is there but is not a readable file is not reported
# as missing: the report says what it found, so a subdirectory is marked "is a
# directory!" and a named pipe, which is neither a file nor a directory, "is
# not a regular file!". Both are made in setup_test.sh.
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
