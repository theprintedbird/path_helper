# --setup, and the search graph the rest of the suite runs against.
#
# Sourced by spec/shell_spec.sh, and first: besides testing what --setup makes,
# this copies the input fixtures into place and adds the symlinked search
# directory, the symlinked and dangling fragment files, the subdirectory and the
# named pipe that the path, error and edge case tests all read through.

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
