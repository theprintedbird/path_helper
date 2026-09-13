# Testing Improvements Task List

## *DONE* Phase 1: Critical Foundation

- Add executable path abstraction via `PATH_HELPER_EXECUTABLE` environment variable
- Replace hardcoded `/usr/local/bin/ruby` with configurable executable path
- Convert expected output fixtures to use `{{HOME}}` placeholder instead of `/root`
- Update test runner to process `{{HOME}}` placeholder with actual home directory
- Standardize debug output format to be language-agnostic (remove Ruby hash syntax)
- Adopt TAP (Test Anything Protocol) output format for test results

## DONE Phase 2: Core Test Coverage

- Add exit code tests for all scenarios (success, failure, help, version)
- Add `--version` output test
- Add `-h/--help` output test
- Add stderr capture and comparison for error tests
- Add test for invalid flag handling
- Add test for missing required arguments
- Add tests for all flag combinations (`--no-etc`, `--no-config`, `--no-lib`)
- Add append mode tests (`-p $PATH`)
- Add debug output tests for all 6 path types (currently only 2)

## DONE Phase 3: Edge Case Coverage

- Add empty input file handling test
- Add test for files with blank lines
- Add test for files with trailing newlines
- Add test for Windows line endings (CRLF)
- Add test for paths with spaces
- Add test for paths with special characters
- Add test for paths with colons (edge case for separator)
- Add test for duplicate paths in same file
- Add test for duplicate paths across files
- Add test for `~` expansion at various positions
- Add test for `$HOME` expansion
- Add test for symlinked path files
- Add test for symlinked directories
- Add test for non-existent paths in path files
- Add test for Unicode characters in paths

## DONE Phase 4: Test Infrastructure

- DONE Create `spec/lib/test_helpers.sh` with common functions
- DONE Split tests into modular files under `spec/tests/`
- DONE Create `setup_test.sh` for setup functionality tests
- DONE Create `path_test.sh` for PATH generation tests
- DONE Create `exit_code_test.sh` for exit code tests
- DONE Create `error_test.sh` for error handling tests
- DONE Create `edge_case_test.sh` for edge cases
- DONE Update main runner to source and execute modular test files
- Add golden file generation mode via `GENERATE_GOLDEN` environment variable

## Phase 5: Platform Support

- Create `spec/fixtures/linux/` directory structure
- Create `spec/fixtures/darwin/` directory structure
- Move current fixtures to linux subdirectory
- Create macOS-specific fixtures with Library paths
- Add platform detection to test runner
- Update fixture paths to use platform-specific directories

### Running the suite on each OS

- First: make `run-shell-tests`/`setup-test-env` work on macOS runners and in an Alpine container (no apt, sudo or `/root` assumptions). `ci.yml` is not a prerequisite
- Run the suite in CI on ubuntu-latest, alpine and macos-latest
- Add a `macos-latest` job to `test-ruby.yml` and `test-crystal.yml` (Darwin fixtures are only checkable on a real Mac)
- Add an Alpine container job to CI so CI matches the local images

### OS-specific tests

- Default search order per OS, and `--lib`/`--config` defaults on each
- `--no-lib` against a real `~/Library/Paths`
- APFS case-insensitivity: `Paths`/`paths` style name clashes
- Unicode filename normalisation (NFC/NFD) and its effect on `paths.d` sort order
- `/etc` and `/tmp` as symlinks to `/private/...`: debug output and "does not exist" report
- Home directory differences (`/Users/<name>`, `/home/runner`, `/root`): `{{HOME}}`, `--setup` output, `~` expansion
- Harness under busybox `sh` (Alpine)
- Harness on BSD userland (macOS): `mktemp`, and no GNU-only `sed -i`/`stat`/`readlink`/`date +%N`
- Harness when `ruby` (timing helper) is missing; remove the apparently unused `bc` dependency
- Crystal on musl vs glibc
- arm64 vs x86_64
- Old macOS system Ruby
- Ordering survives Apple's `/usr/libexec/path_helper` in a macOS login shell (overlaps with shell integration tests)

## Phase 6: CI/CD and Documentation

- DONE Update GitHub Actions workflow to v4 for all actions
- DONE Add `PATH_HELPER_DOCKER_INSTANCE` environment variable to CI workflow
- Fix fixture setup steps in CI workflow
- Add performance regression tests with timing bounds
- Create `SPEC.md` behaviour specification document
- Document input/output contract in specification
- Document all exit codes in specification
- Document error message formats in specification
- Document flag behaviour and interactions in specification

## Phase 7: Multi-Language Verification

- Create test matrix for running against multiple executables
- Add CI job to compare outputs across implementations
- Create output diff reporting for cross-implementation testing
- Document required behavioural guarantees for implementations
- Add implementation compliance checklist
