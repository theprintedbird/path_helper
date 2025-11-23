# GitHub Actions Improvement Roadmap

## Overview

This document outlines the current issues with the GitHub Actions workflow and the planned improvements to modernize the CI/CD pipeline while maintaining language agnosticism for future multi-language implementations (Crystal, Go, etc.).

## Current State Analysis

### Workflow File: `.github/workflows/path_helper_tests.yml`

#### Issues Identified

1. **Outdated GitHub Actions**
   - Using `actions/checkout@v2` (current: v4)
   - Using `actions/upload-artifact@v2` (current: v4)
   - Security and performance improvements available in newer versions

2. **Missing Environment Variable**
   - Test script requires `PATH_HELPER_DOCKER_INSTANCE` environment variable
   - Workflow doesn't set this variable, causing tests to exit early
   - Located in `spec/shell_spec.sh:7-15`

3. **Incorrect File Path Reference**
   - Workflow references `/tmp/install.sh` (line 46)
   - Actual install script is at `docker/install.sh`
   - This would cause the installation step to fail

4. **Outdated Ruby Versions**
   - Testing with Ruby 2.3.7 (EOL March 2019)
   - Missing recent Ruby versions (3.0, 3.1, 3.2)
   - Should focus on maintained versions

5. **Shell Script Issues**
   - `spec/shell_spec.sh:187` uses `return` instead of `exit`
   - `return` doesn't work properly outside of functions in shell scripts
   - Will cause incorrect exit codes in CI environment

6. **No Dependency Caching**
   - No caching of installed packages
   - Slower CI runs due to repeated package installations

7. **Limited Workflow Controls**
   - No concurrency control (multiple runs can execute simultaneously)
   - No manual trigger option (`workflow_dispatch`)
   - No workflow permissions defined

8. **Poor Test Observability**
   - Test results only uploaded on failure
   - No detailed reporting of individual test results
   - Hard to diagnose failures without full context

## Proposed Improvements

### Phase 1: Critical Fixes

#### 1.1 Update GitHub Actions Versions
```yaml
- uses: actions/checkout@v4
- uses: actions/upload-artifact@v4
```

#### 1.2 Set Required Environment Variables
```yaml
env:
  PATH_HELPER_DOCKER_INSTANCE: true
```

#### 1.3 Fix Install Script Path
```yaml
- name: Run install script
  run: |
    sudo sh -x docker/install.sh
```

#### 1.4 Fix Shell Script Exit Code
Change `spec/shell_spec.sh:187` from `return $PASS` to `exit $PASS`

### Phase 2: Modernization

#### 2.1 Update Ruby Version Matrix
Remove EOL versions, add current stable versions:
```yaml
matrix:
  ruby-version: ['2.7', '3.0', '3.1', '3.2', '3.3']
```

#### 2.2 Add Workflow Controls
```yaml
on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
```

#### 2.3 Add Package Caching
```yaml
- name: Cache APT packages
  uses: actions/cache@v4
  with:
    path: /var/cache/apt
    key: ${{ runner.os }}-apt-${{ hashFiles('**/*.yml') }}
```

#### 2.4 Improve Test Reporting
- Upload test results on both success and failure
- Add step summaries for better visibility
- Include detailed error information

### Phase 3: Language Agnostic Foundation

#### 3.1 Restructure Test Workflows
Create a modular workflow structure that supports multiple language implementations:

```
.github/
├── workflows/
│   ├── test-ruby.yml          # Ruby implementation tests
│   ├── test-crystal.yml       # Crystal implementation (future)
│   ├── test-go.yml            # Go implementation (future)
│   └── ci.yml                 # Main workflow that coordinates all tests
└── actions/
    ├── setup-test-env/        # Shared test environment setup
    └── run-shell-tests/       # Language-agnostic shell test runner
```

#### 3.2 Create Composite Actions
Reusable actions for common setup steps:

**`.github/actions/setup-test-env/action.yml`**
- Install system dependencies (alpine-pbuilder)
- Set up test directory structure
- Copy test fixtures
- Language-agnostic setup

**`.github/actions/run-shell-tests/action.yml`**
- Execute shell_spec.sh
- Process results
- Upload artifacts
- Works regardless of implementation language

#### 3.3 Implementation-Specific Workflows
Each language gets its own workflow file with:
- Language-specific setup (Ruby/Crystal/Go installation)
- Version matrix for that language
- Calls to shared composite actions
- Implementation-specific tests

#### 3.4 Unified CI Workflow
Main workflow that:
- Runs all language implementation tests in parallel
- Aggregates results
- Provides single status check for PRs
- Supports future expansion

### Phase 4: Enhanced Testing & Observability

#### 4.1 Add Test Result Reporting
- Integrate test reporting action (e.g., `dorny/test-reporter@v1`)
- Generate test summaries in PR comments
- Track test trends over time

#### 4.2 Add Code Coverage (when applicable)
- Track coverage per implementation
- Compare coverage across languages
- Set minimum coverage thresholds

#### 4.3 Add Performance Benchmarks
- Benchmark path generation speed
- Compare performance across implementations
- Detect performance regressions

#### 4.4 Add Integration Tests
- Test actual shell integration (bash, zsh, fish)
- Validate output in different environments
- Test edge cases and error conditions

## Implementation Priority

### Immediate (Required for CI to work)
1. Fix `PATH_HELPER_DOCKER_INSTANCE` environment variable
2. Fix install script path
3. Fix shell script exit code
4. Update GitHub Actions to v4

### Short-term (Within next release)
1. Update Ruby version matrix
2. Add workflow controls and permissions
3. Add package caching
4. Improve test reporting

### Medium-term (Next major version)
1. Create language-agnostic workflow structure
2. Develop composite actions for shared setup
3. Prepare for multi-language implementations
4. Add comprehensive test reporting

### Long-term (Future development)
1. Add Crystal implementation with tests
2. Add Go implementation with tests
3. Add performance benchmarks
4. Add integration tests for multiple shells

## Success Metrics

- CI runs complete successfully on all supported Ruby versions
- Test execution time reduced by at least 30% (via caching)
- Clear test results visible in PR checks
- Easy to add new language implementations
- Zero-friction developer experience

## Migration Path

1. Create new workflow files alongside existing one
2. Test new workflows on feature branch
3. Validate all tests pass with new configuration
4. Replace old workflow with new one
5. Document new workflow structure for contributors

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Caching Dependencies](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
