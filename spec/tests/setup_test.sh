# Sourced by spec/shell_spec.sh:
# - Tests what --setup creates,
# - copies the input fixtures into place, in the user segment
# - sets up the other segment and copies its own inputs there
# - adds the symlinked search directory
# - adds symlinked and dangling fragment files
# - adds a subdirectory and named pipe that the path, error and edge case tests use.

# Nothing should have been set up yet, so finding something is a failure.
if test_setup; then
	tap_not_ok "the paths are absent before setup runs"
	tap_yaml "found a set up path tree before --setup was run"
else
	tap_ok "the paths are absent before setup runs"
fi

# --setup creates segments in search order. The inputs go in the user
# segment for the specified platform (see USER_SEGMENT in spec/shell_spec.sh)
# ~/Library/Paths on macOS, ~/.config/paths elsewhere
"$EXECUTABLE" --setup --$USER_SEGMENT --no-$OTHER_SEGMENT --quiet
cp -R spec/fixtures/moredirs/* "$HOME/$USER_PATHS"

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

# The other segment -- the one the platform does not search by default,
# ~/.config/paths on macOS and ~/Library/Paths elsewhere -- gets a tree and
# inputs of its own. Without them, switching it off (or on) could not change the
# output, so the --no-$OTHER_SEGMENT tests in path_test.sh would pass whatever
# the switch did. It is also what gives `--no-lib` a real ~/Library/Paths to act
# on under Linux (on macOS that is the user segment, populated above).
# Its inputs (spec/fixtures/otherdirs/) are few and distinct from the user
# segment's, plus a line from each of the user and etc segments, so the output
# shows where the segment falls in the search order.
# It is laid out by --setup with only the other segment switched on, which
# shows that the switch is what enables it and that the other two segments are
# left alone.
"$EXECUTABLE" --setup --$OTHER_SEGMENT --no-$USER_SEGMENT --no-etc --quiet
cp -R spec/fixtures/otherdirs/* "$HOME/$OTHER_PATHS"

if [ -d "$HOME/$OTHER_PATHS/c_include_paths.d" ] &&
   [ -f "$HOME/$OTHER_PATHS/pkg_config_paths" ] &&
   [ -f "$HOME/$OTHER_PATHS/paths" ] &&
   [ -f "$HOME/$OTHER_PATHS/paths.d/10-other" ] &&
   [ -f "$HOME/$OTHER_PATHS/manpaths" ]; then
	tap_ok "setup creates the $OTHER_SEGMENT segment when it is switched on"
else
	tap_not_ok "setup creates the $OTHER_SEGMENT segment when it is switched on"
	tap_yaml "--setup --$OTHER_SEGMENT did not create the $OTHER_SEGMENT tree at ~/$OTHER_PATHS"
fi

# A segment's directory may be a symlink. A dotfile repo that keeps its
# fragments together and links them into place is the basic case. It
# has to be walked like a real directory rather than skipped. `Dir.exist?` and
# `Dir.exists?` both follow the link.
# /etc/paths.d is left empty, so it is can be replaced without disturbing anything.
# It is swapped only after the assertion above has checked on --setup.
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
# the directory above, so one is linked into the user segment's `paths.d`. A
# second link is left dangling.
mkdir -p "$HOME/symlinked-fragments"
cp -R spec/fixtures/linkedfile/* "$HOME/symlinked-fragments"
ln -s "$HOME/symlinked-fragments/paths-fragment" "$HOME/$USER_PATHS/paths.d/15-symlinked-file"
ln -s "$HOME/symlinked-fragments/no-such-fragment" "$HOME/$USER_PATHS/paths.d/16-dangling"

if [ -L "$HOME/$USER_PATHS/paths.d/15-symlinked-file" ] &&
   [ -f "$HOME/$USER_PATHS/paths.d/15-symlinked-file" ] &&
   [ -L "$HOME/$USER_PATHS/paths.d/16-dangling" ] &&
   [ ! -e "$HOME/$USER_PATHS/paths.d/16-dangling" ]; then
	tap_ok "paths.d holds a symlinked fragment file and a dangling one"
else
	tap_not_ok "paths.d holds a symlinked fragment file and a dangling one"
	tap_yaml "the test could not put symlinked files in the search graph"
fi

# A subdirectory and a named pipe are created here rather than kept as fixtures,
# since git keeps neither an empty directory nor a pipe.
# Neither can be read as a list of paths, and reading a pipe would block until
# something wrote to it, so both are passed over.
mkdir "$HOME/$USER_PATHS/paths.d/21-subdirectory"
mkfifo "$HOME/$USER_PATHS/paths.d/22-fifo"

if [ -d "$HOME/$USER_PATHS/paths.d/21-subdirectory" ] &&
   [ -p "$HOME/$USER_PATHS/paths.d/22-fifo" ]; then
	tap_ok "paths.d holds a subdirectory and a named pipe"
else
	tap_not_ok "paths.d holds a subdirectory and a named pipe"
	tap_yaml "the test could not put a subdirectory and a pipe in the search graph"
fi
