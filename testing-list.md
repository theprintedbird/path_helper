# Testing Improvements Task List

## Phase 1: Critical Foundation

- Add executable path abstraction via `PATH_HELPER_EXECUTABLE` environment variable
- Replace hardcoded `/usr/local/bin/ruby` with configurable executable path
- Convert expected output fixtures to use `{{HOME}}` placeholder instead of `/root`
- Update test runner to process `{{HOME}}` placeholder with actual home directory
- Standardize debug output format to be language-agnostic (remove Ruby hash syntax)
- Adopt TAP (Test Anything Protocol) output format for test results

## Phase 2: Core Test Coverage

- Add exit code tests for all scenarios (success, failure, help, version)
- Add `--version` output test
- Add `-h/--help` output test
- Add stderr capture and comparison for error tests
- Add test for invalid flag handling
- Add test for missing required arguments
- Add tests for all flag combinations (`--no-etc`, `--no-config`, `--no-lib`)
- Add append mode tests (`-p $PATH`)
- Add debug output tests for all 6 path types (currently only 2)

## Phase 3: Edge Case Coverage

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

## Phase 4: Test Infrastructure

- Create `spec/lib/test_helpers.sh` with common functions
- Split tests into modular files under `spec/tests/`
- Create `setup_test.sh` for setup functionality tests
- Create `path_test.sh` for PATH generation tests
- Create `exit_code_test.sh` for exit code tests
- Create `error_test.sh` for error handling tests
- Create `edge_case_test.sh` for edge cases
- Update main runner to source and execute modular test files
- Add golden file generation mode via `GENERATE_GOLDEN` environment variable

## Phase 5: Platform Support

- Create `spec/fixtures/linux/` directory structure
- Create `spec/fixtures/darwin/` directory structure
- Move current fixtures to linux subdirectory
- Create macOS-specific fixtures with Library paths
- Add platform detection to test runner
- Update fixture paths to use platform-specific directories

## Phase 6: CI/CD and Documentation

- Update GitHub Actions workflow to v4 for all actions
- Add `PATH_HELPER_DOCKER_INSTANCE` environment variable to CI workflow
- Fix fixture setup steps in CI workflow
- Add performance regression tests with timing bounds
- Create `SPEC.md` behavior specification document
- Document input/output contract in specification
- Document all exit codes in specification
- Document error message formats in specification
- Document flag behavior and interactions in specification

## Phase 7: Multi-Language Verification

- Create test matrix for running against multiple executables
- Add CI job to compare outputs across implementations
- Create output diff reporting for cross-implementation testing
- Document required behavioral guarantees for implementations
- Add implementation compliance checklist
