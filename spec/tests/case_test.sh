# Names that differ only by case. macOS's default APFS volume is
# case-insensitive but case-preserving, where the Linux containers and CI
# runners are case-sensitive, so the same inputs can mean one file or two.
# The file system is probed at run time (is_case_insensitive) rather than
# assumed from PLATFORM, and each test expects whatever that file system
# should give. On a case-sensitive one that is what the implementations do
# with two distinct names; on a case-insensitive one it is what they do when
# the second name is the first file again.
#
# Every test builds its own scratch HOME, so nothing here touches the tree
# laid out by setup_test.sh. The user segment ($USER_PATHS) is the one the
# platform searches by default, and /etc is switched off.
#
# Sourced by spec/shell_spec.sh after setup_test.sh

case_home="$(mktemp -d /tmp/path_helper.XXXXXX)"
if is_case_insensitive "$case_home"; then
	case_insensitive=true
	tap_comment "File system: case-insensitive (names differing only by case are one file)"
else
	case_insensitive=false
	tap_comment "File system: case-sensitive (names differing only by case are two files)"
fi
case_dir="$case_home/$USER_PATHS/paths.d"
mkdir -p "$case_dir"

# Fragments are read in byte order, not in a case-insensitive or locale order,
# so every upper-case letter sorts before every lower-case one: `10-Zeta`
# before `10-alpha`. Ruby's and Crystal's String sorts both compare bytes. The
# names do not clash, so this holds on either kind of file system.
printf '/opt/alpha/bin\n' > "$case_dir/10-alpha"
printf '/opt/zeta/bin\n' > "$case_dir/10-Zeta"
test_path_under_home "fragments sort by byte, upper case before lower" \
	"$case_home" "/opt/zeta/bin:/opt/alpha/bin" -p --no-etc
rm -f "$case_dir/10-alpha" "$case_dir/10-Zeta"

# Two fragments whose names differ only by case. On a case-sensitive file
# system they are two files, both read, upper case first. On a
# case-insensitive one the second write opens the first file, keeping its
# name (`10-Foo`) but replacing its contents, so there is one fragment and
# only the second component. The debug report lists entries as the directory
# listing spells them, so it shows `10-Foo` and never `10-foo` there.
printf '/opt/upper/bin\n' > "$case_dir/10-Foo"
printf '/opt/lower/bin\n' > "$case_dir/10-foo"
if [ "$case_insensitive" = true ]; then
	test_path_under_home "fragment names differing only by case are one file, read once" \
		"$case_home" "/opt/lower/bin" -p --no-etc
	test_files_listed_under_home "the debug report lists that file once, as first spelt" \
		"$case_home" "$case_dir/10-Foo" -p --no-etc
else
	test_path_under_home "fragment names differing only by case are both read, upper case first" \
		"$case_home" "/opt/upper/bin:/opt/lower/bin" -p --no-etc
	test_files_listed_under_home "the debug report lists both files, upper case first" \
		"$case_home" "$case_dir/10-Foo
$case_dir/10-foo" -p --no-etc
fi
rm -f "$case_dir/10-Foo" "$case_dir/10-foo"

# Components differing only by case are different text, so both are kept.
# De-duplication compares lines, not the directories they name, even where
# the file system would resolve them to the same place (just as `/opt/x` and
# `/opt/x/` are both kept -- see edge_case_test.sh).
printf '/opt/Mixed/bin\n/opt/mixed/bin\n' > "$case_dir/10-mixed"
test_path_under_home "components differing only by case are both kept" \
	"$case_home" "/opt/Mixed/bin:/opt/mixed/bin" -p --no-etc
rm -f "$case_dir/10-mixed"

# The directory and the plain file spelt in another case than the one
# path_helper asks for: `PATHS.d` and `PATHS` rather than `paths.d` and
# `paths`. A case-insensitive file system finds them under the asked-for
# names, and the debug report prints the names it asked for, not the on-disk
# spelling; a case-sensitive one does not find them at all.
rmdir "$case_dir"
upper_dir="$case_home/$USER_PATHS/PATHS.d"
mkdir -p "$upper_dir"
printf '/opt/from-dir/bin\n' > "$upper_dir/01-upper"
printf '/opt/from-file/bin\n' > "$case_home/$USER_PATHS/PATHS"
if [ "$case_insensitive" = true ]; then
	test_path_under_home "a paths.d and paths spelt in upper case are found" \
		"$case_home" "/opt/from-dir/bin:/opt/from-file/bin" -p --no-etc
	test_files_listed_under_home "the debug report names them as path_helper spells them" \
		"$case_home" "$case_home/$USER_PATHS/paths.d/01-upper
$case_home/$USER_PATHS/paths" -p --no-etc
else
	test_path_under_home "a paths.d and paths spelt in upper case are not found" \
		"$case_home" "" -p --no-etc
	test_files_listed_under_home "the debug report lists no files for them" \
		"$case_home" "" -p --no-etc
fi
rm -rf "$upper_dir" "$case_home/$USER_PATHS/PATHS"

# The segment root itself spelt differently: `LIBRARY/PATHS` for
# `Library/Paths` on a Mac, `.CONFIG/PATHS` for `.config/paths` elsewhere.
rm -rf "${case_home:?}/${USER_PATHS%%/*}"
upper_root="$case_home/$(printf '%s' "$USER_PATHS" | tr '[:lower:]' '[:upper:]')"
mkdir -p "$upper_root/paths.d"
printf '/opt/from-root/bin\n' > "$upper_root/paths.d/01-root"
if [ "$case_insensitive" = true ]; then
	test_path_under_home "a user segment directory spelt in upper case is found" \
		"$case_home" "/opt/from-root/bin" -p --no-etc
	test_files_listed_under_home "the debug report names it as path_helper spells it" \
		"$case_home" "$case_home/$USER_PATHS/paths.d/01-root" -p --no-etc
else
	test_path_under_home "a user segment directory spelt in upper case is not found" \
		"$case_home" "" -p --no-etc
	test_files_listed_under_home "the debug report lists no files from it" \
		"$case_home" "" -p --no-etc
fi

rm -rf "$case_home"
unset case_home case_dir upper_dir upper_root case_insensitive
