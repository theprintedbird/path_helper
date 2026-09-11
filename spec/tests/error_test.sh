# Exit status and what goes on which stream. A refusal exits non-zero with
# nothing on stdout and says why on stderr; --version and --help exit 0 with
# nothing on stdout, for the same reason -- stdout carries the path.
#
# Sourced by spec/shell_spec.sh after setup_test.sh.

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
