# Awkward input files and arguments: empty and blank lines, line endings,
# spaces, special and non-ASCII characters, symlinks, entries that are not
# readable files, $HOME and ~, duplicates, and colons.
#
# Sourced by spec/shell_spec.sh after setup_test.sh

# Edge cases in the input files.
# Empty files are skipped, as are blank lines. Adding `::`, would put
# the current working directory on PATH, which is a security problem.
# Spec: spec/fixtures/moredirs/paths.d/01-empty
# It sorts first so anything leaked will show up at the head of the path.
# The manpath tests also check this.
# debug_manpath.txt has files listed with no lines beneath them.
test_a_path "an empty input file adds no components" "path.txt" "-p"
test_a_path "an empty input file is still listed in the debug report" "debug_path.txt" "-p" "--debug"

# An empty component joins as `::` so must be dropped prior to the debug
# report. Blank lines must also be removed.
# Spec: spec/fixtures/moredirs/paths.d/02-blank-lines
test_a_path "blank lines add no components" "path.txt" "-p"
test_a_path "blank lines are absent from the debug report" "debug_path.txt" "-p" "--debug"

# A file's last line may or may not be terminated. Both readers chomp, so an
# unterminated last line still has to arrive as a component rather than being
# dropped or run onto the next file's first line, and a terminated one must not
# produce a phantom empty component after it.
# Spec: spec/fixtures/moredirs/paths.d/07-trailing-newline ends with a newline,
# 08-no-trailing-newline does not (files ending with several newlines are tested via
# 02-blank-lines').
test_a_path "a last line is read with or without a trailing newline" "path.txt" "-p"
test_a_path "both files read the same way in the debug report" "debug_path.txt" "-p" "--debug"

# The app must handle Windows line endings. A CRLF blank line must
# also still count as blank and not become an "\r".
# Spec: spec/fixtures/moredirs/paths.d/09-crlf.
test_a_path "CRLF line endings do not leak a carriage return" "path.txt" "-p"
test_a_path "CRLF lines are clean in the debug report" "debug_path.txt" "-p" "--debug"

# Path env vars like PATH, MANPATH etc do accept spaces, so path_helper accepts spaces.
# Nothing is stripped or collapsed, so a component arrives verbatim, and spaces never split
# items, only completely blank lines are dropped. The caller is still recommended to quote
# calls, e.g. `export PATH="$(path_helper -p)"`.
# Spec: spec/fixtures/moredirs/paths.d/11-spaces.
test_a_path "spaces within a path are preserved" "path.txt" "-p"
test_a_path "spaces around a path are not stripped" "path.txt" "-p"
test_a_path "spaces within a path survive the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a path with spaces is appended verbatim" "path-spaces-appended.txt" "-p" "/opt/appended with spaces/bin:~/appended with spaces"

# Special characters (except colon)
# Spec: spec/fixtures/moredirs/paths.d/12-special-chars.
test_a_path "special characters within a path are preserved" "path.txt" "-p"
test_a_path "special characters survive the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a path with special characters is appended verbatim" \
	"path-special-chars-appended.txt" "-p" '/opt/appended*glob?/bin:/opt/appended$(dollars)&{braces}/bin'

# Non-ASCII paths.
# Spec: spec/fixtures/moredirs/paths.d/13-unicode.
test_a_path "non-ASCII characters within a path are preserved" "path.txt" "-p"
test_a_path "non-ASCII characters survive the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a path with non-ASCII characters is appended verbatim" \
	"path-unicode-appended.txt" "-p" "/opt/appended/ünïcødé/bin:~/appended/漢字"

# Non-existent paths.
# Spec: spec/fixtures/moredirs/paths.d/14-nonexistent.
test_a_path "a non-existent directory is still a component" "path.txt" "-p"
test_a_path "a non-existent directory is listed in the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a non-existent directory given as an argument is appended too" \
	"path-nonexistent-appended.txt" "-p" "/opt/appended-does-not-exist/bin:~/appended-does-not-exist"

# Symlinked search directory. /etc/paths.d is a symlink to
# $HOME/symlinked-paths.d for the whole run.
test_a_path "a symlinked search directory is walked" "path.txt" "-p"
test_a_path "a symlinked search directory is reported by the path it was reached through" \
	"debug_path.txt" "-p" "--debug"

# The set up creates `15-symlinked-file`
# `16-dangling` points at nothing and contributes no components.
# Both are linked in for the whole run (see setup_test.sh).
# The debug report names each by its path in paths.d rather than by what it
# resolves to, and marks the dangling one with "does not exist!"
test_a_path "a symlinked fragment file is read" "path.txt" "-p"
test_a_path "a dangling symlink adds nothing and is marked in the debug report" \
	"debug_path.txt" "-p" "--debug"

# Entries that do exist but are not readable are not reported as missing.
# Subdirectories are marked with "is a directory!"
# Named pipes, which are neither a file nor a directory, show "is not a regular file!".
# Both are created in setup_test.sh.
test_a_path "a subdirectory and a named pipe in paths.d add nothing" "path.txt" "-p"
test_a_path "a subdirectory and a named pipe are marked for what they are in the debug report" \
	"debug_path.txt" "-p" "--debug"

# Regular, unreadable files. See test_unreadable_fragment for why this runs as *nobody*.
test_unreadable_fragment "an unreadable fragment adds nothing" \
	"unreadable_path.txt" "-p" "--no-etc"
test_unreadable_fragment "an unreadable fragment is marked in the debug report" \
	"debug_unreadable.txt" "-p" "--no-etc" "--debug"

# `$HOME` is not `~`. Only a literal tilde is expanded, so a fragment written
# with a shell variable in it arrives with that variable still in it -- and
# since the output of `$(path_helper -p)` is not re-scanned by the shell, that
# component reaches PATH as the four characters `$HOME`, not as a home
# directory. It is left alone rather than being dropped or expanded.
# Spec: spec/fixtures/moredirs/paths.d/17-dollar-home
test_a_path "a literal \$HOME is not expanded" "path.txt" "-p"
test_a_path "a literal \$HOME survives the debug report" "debug_path.txt" "-p" "--debug"
test_a_path "a literal \$HOME in an argument is appended verbatim" \
	"path-dollar-home-appended.txt" "-p" '$HOME/appended/bin'

# `~` expands to whatever HOME is set to at run time
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

# Duplicate components across files.
# First occurrence wins and keeps its place.
# Spec: spec/fixtures/moredirs/paths.d/19-dupes-across-files names three components
# that already appear elsewhere, one from each direction:
#   /usr/local/bin  is in /etc/paths, a later segment, so this copy wins and
#                   the /etc/paths one is the duplicate;
#   /opt/local/sbin is in the user segment's plain paths file, the same segment,
#                   which is read after the directory, so this copy wins too;
#   /opt/pkg/bin    is already in 04-llvm and 05-pkgsrc, earlier in the same
#                   directory, so here it is the duplicate.
# The debug report marks whichever occurrence lost with ✗.
test_a_path "a component repeated across files appears once, at its first occurrence" \
	"path.txt" "-p"
test_a_path "the debug report marks the losing occurrence whichever file it is in" \
	"debug_path.txt" "-p" "--debug"

# Duplicates components in files.
# Spec: spec/fixtures/moredirs/paths.d/20-dupes-in-file
# Its last line is `/opt/dupe/bin/`, the first component with a trailing
# slash. The comparison is on the text of the line, not on the directory it
# resolve to.
test_a_path "a component repeated within a file appears once" "path.txt" "-p"
test_a_path "every repeat within a file is marked in the debug report" \
	"debug_path.txt" "-p" "--debug"

# Colons are not allowed within path declarations as they are separators for PATH et al
# When found, they are rejected but do not fail the whole run.
# A message is put on STDERR.
# Spec: spec/fixtures/moredirs/paths.d/06-colons.
test_a_path_with_stderr "a line containing a colon is dropped and reported" \
	"path.txt" "colons_warning.txt" "-p"
test_a_path_with_stderr "--quiet silences the report but still drops the line" \
	"path.txt" "no_warnings.txt" "-p" "-q"
test_a_path "a dropped line is absent from the debug report" "debug_path.txt" "-p" "--debug"
