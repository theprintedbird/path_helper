# What real shells make of the output. Every other test compares the bytes
# path_helper prints; these check that the documented ways of using them work
# in sh, bash and zsh: `export PATH=$(path_helper -p "$PATH")` in a profile,
# and the lines --setup prints to paste into one.
#
# Each shell runs as a profile would run it, non-interactive and reading no rc
# files, with an emptied environment (run_in_shell). What it exported is read
# back by a child process (write_env_reporter), since that is what the
# variables are for. A shell that is not installed has its test points
# skipped. `sh` is /bin/sh, whatever that is here.
#
# Everything happens in a scratch HOME, whose user segment names two
# directories: one with a space in its name, holding a probe program, and an
# ordinary one. Nothing here touches the tree laid out by setup_test.sh.
#
# Sourced by spec/shell_spec.sh after setup_test.sh

tap_comment "sh is: $(sh_flavour)"

shell_home="$(mktemp -d /tmp/path_helper.XXXXXX)"
shell_spaced="$shell_home/my bin"
shell_plain="$shell_home/tools/bin"
shell_reporter="$shell_home/report_env.rb"
shell_snippet="$shell_home/snippet.sh"
shell_base="$(shell_base_path)"

mkdir -p "$shell_home/$USER_PATHS/paths.d" "$shell_spaced" "$shell_plain"
printf '%s\n%s\n' "$shell_spaced" "$shell_plain" > "$shell_home/$USER_PATHS/paths.d/10-shell"
printf '#!/bin/sh\necho "path-helper-probe ran"\n' > "$shell_spaced/path-helper-probe"
chmod +x "$shell_spaced/path-helper-probe"
write_env_reporter "$shell_reporter"

# The path the shells should end up with: the user segment, the spaced entry
# intact, then the PATH they started with. /etc is switched off so its
# contents do not matter here.
shell_expected_path="$shell_spaced:$shell_plain:$shell_base"
shell_direct_path="$(HOME="$shell_home" PATH="$shell_base" "$EXECUTABLE" -p "$shell_base" --no-etc 2>/dev/null)"
assert_same "-p keeps an entry with a space intact and appends the current path" \
	"the path" "$shell_expected_path" "$shell_direct_path" "-p '$shell_base' --no-etc"

# The lines --setup prints for a shell profile, from the heading down. A dry
# run prints them without creating anything.
HOME="$shell_home" PATH="$shell_base" "$EXECUTABLE" --setup --dry-run --no-etc 2>/dev/null |
	sed -n '/^# Put this in/,$p' > "$shell_snippet"

# What each variable should be once the snippet has run: what the executable
# prints for its switch, run directly in the same HOME. The snippet's runs
# take no current path, so neither do these.
shell_snippet_expected=""
shell_snippet_names=""
while read -r shell_var shell_switch; do
	# macOS strips DYLD_* variables from the environment of a protected
	# binary, the reporter's ruby included if it is the system one, so there
	# they can only be checked with a ruby of its own.
	if [ "$PLATFORM" = darwin ]; then
		case "$shell_var:$(command -v ruby)" in
			DYLD_*:/usr/bin/*|DYLD_*:/System/*)
				tap_comment "Not checking $shell_var from the snippet: the system ruby cannot see it"
				continue
				;;
		esac
	fi
	shell_snippet_names="$shell_snippet_names $shell_var"
	shell_snippet_expected="$shell_snippet_expected${shell_snippet_expected:+
}$shell_var=$(HOME="$shell_home" PATH="$shell_base" "$EXECUTABLE" "$shell_switch" 2>/dev/null)"
done <<EOF
$SNIPPET_VARS
EOF

for shell_name in sh bash zsh; do
	if [ "$shell_name" != sh ] && ! command -v "$shell_name" >/dev/null 2>&1; then
		tap_skip "$shell_name: export PATH=\$(path_helper -p \"\$PATH\") exports the path -p prints" "$shell_name not installed"
		tap_skip "$shell_name: a program in the new PATH is found and runs" "$shell_name not installed"
		tap_skip "$shell_name: the --setup snippet exports each variable as path_helper prints it" "$shell_name not installed"
		continue
	fi

	# The one-line form, as a profile would have it. `export NAME=$(...)` is
	# the form a shell is most likely to field-split, so it is the one used.
	# The reporter then shows what a child process was given, and the probe
	# is looked up and run through the new PATH, which in zsh also means the
	# tied `path` array has followed it.
	shell_out="$(run_in_shell "$shell_name" "$shell_home" '
		export PATH=$("$EXE" -p "$PATH" --no-etc)
		"$RUBY" "$HOME/report_env.rb" PATH
		command -v path-helper-probe
		path-helper-probe
	' 2>&1)"

	assert_same "$shell_name: export PATH=\$(path_helper -p \"\$PATH\") exports the path -p prints" \
		"the exported PATH" "PATH=$shell_direct_path" \
		"$(printf '%s\n' "$shell_out" | sed -n '1p')" \
		"$shell_name: export PATH=\$(\"\$EXE\" -p \"\$PATH\" --no-etc)"

	assert_same "$shell_name: a program in the new PATH is found and runs" \
		"the probe lookup and its output" "$shell_spaced/path-helper-probe
path-helper-probe ran" \
		"$(printf '%s\n' "$shell_out" | sed -n '2,$p')" \
		"$shell_name: command -v path-helper-probe; path-helper-probe"

	# The snippet sourced as a profile would be, then every variable it names
	# read back from a child.
	shell_out="$(run_in_shell "$shell_name" "$shell_home" "
		. \"\$HOME/snippet.sh\"
		\"\$RUBY\" \"\$HOME/report_env.rb\" $shell_snippet_names
	" 2>&1)"

	if [ -s "$shell_snippet" ]; then
		assert_same "$shell_name: the --setup snippet exports each variable as path_helper prints it" \
			"the exported variables" "$shell_snippet_expected" "$shell_out" \
			"$shell_name: . <the --setup --dry-run --no-etc snippet>"
	else
		tap_not_ok "$shell_name: the --setup snippet exports each variable as path_helper prints it"
		tap_yaml "--setup --dry-run printed no snippet to source"
	fi
	if [ -s "$shell_snippet" ] && [ "$shell_out" != "$shell_snippet_expected" ]; then
		tap_comment_file "snippet" "$shell_snippet"
	fi
done

rm -rf "$shell_home"
unset shell_home shell_spaced shell_plain shell_reporter shell_snippet shell_base \
	shell_expected_path shell_direct_path shell_snippet_expected shell_snippet_names \
	shell_var shell_switch shell_name shell_out
