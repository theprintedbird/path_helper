# TODO

## Notes

### Workflow Execution Order
1. Critical fixes must be implemented first (workflow won't work otherwise)
2. Short-term improvements can be done incrementally
3. Medium-term restructuring should be done as a cohesive unit
4. Long-term features can be added as needed

### Testing Strategy
- Test all changes on a feature branch first
- Validate workflow with `act` locally before pushing
- Monitor first few runs carefully for issues
- Keep rollback plan ready for critical workflows

### Multi-Language Support
The goal is to support multiple language implementations (Ruby, Crystal, Go) while maintaining a single, language-agnostic test suite (shell_spec.sh). The workflow structure should:
- Support language-specific setup and dependencies
- Run the same shell-based tests for all implementations
- Allow parallel execution of tests across languages
- Provide unified reporting and status checks

### Dependencies
- `alpine-pbuilder` package required for tests
- Shell test framework in `spec/shell_spec.sh`
- Test fixtures in `spec/fixtures/`
- Docker setup in `docker/` directory

### Resources
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Composite Actions Guide](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- [Matrix Strategy](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [Act - Local Testing](https://github.com/nektos/act)


###### Backlog

To Do - Medium Term

Language-Agnostic Infrastructure

- Create `.github/actions/setup-test-env/` composite action <!-- backlog: 1763431283 -->
- Create `.github/actions/run-shell-tests/` composite action <!-- backlog: 1763431283 -->
- Extract common test setup logic from workflow <!-- backlog: 1763431283 -->
- Create reusable test execution wrapper <!-- backlog: 1763431283 -->

Workflow Restructuring

- Create `test-ruby.yml` workflow (language-specific) <!-- backlog: 1763431283 -->
- Create `ci.yml` main workflow (orchestrator) <!-- backlog: 1763431283 -->
- Add workflow for testing Docker builds <!-- backlog: 1763431283 -->
- Add workflow for release automation <!-- backlog: 1763431283 -->

Multi-Language Support Preparation

- Design workflow structure for Crystal implementation <!-- backlog: 1763431283 -->
- Design workflow structure for Go implementation <!-- backlog: 1763431283 -->
- Create template for adding new language implementations <!-- backlog: 1763431283 -->
- Document multi-language testing strategy <!-- backlog: 1763431283 -->

Enhanced Testing

- Add shell integration tests (bash, zsh, sh) <!-- backlog: 1763431283 -->
- Add tests for different OS environments (Ubuntu, Alpine, macOS) <!-- backlog: 1763431283 -->
- Add edge case tests for path handling <!-- backlog: 1763431283 -->
- Add validation tests for setup command <!-- backlog: 1763431283 -->

To Do - Long Term


Future Language Implementations

- Implement `test-crystal.yml` workflow (when Crystal implementation exists) <!-- backlog: 1763431283 -->
- Implement `test-go.yml` workflow (when Go implementation exists) <!-- backlog: 1763431283 -->
- Add cross-language compatibility tests <!-- backlog: 1763431283 -->
- Add performance comparison between implementations <!-- backlog: 1763431283 -->

Advanced Features

- Add test result reporting with PR comments <!-- backlog: 1763431283 -->
- Add code coverage tracking (per language) <!-- backlog: 1763431283 -->
- Add performance benchmarking workflow <!-- backlog: 1763431283 -->
- Add automated changelog generation <!-- backlog: 1763431283 -->
- Add automated release creation on version tags <!-- backlog: 1763431283 -->

Quality & Security

- Add dependency vulnerability scanning <!-- backlog: 1763431283 -->
- Add SAST (static analysis security testing) <!-- backlog: 1763431283 -->
- Add workflow security best practices audit <!-- backlog: 1763431283 -->
- Add automated dependency updates (Dependabot) <!-- backlog: 1763431283 -->

Developer Experience

- Add local GitHub Actions testing setup (act) <!-- backlog: 1763431283 -->
- Add pre-commit hooks for common issues <!-- backlog: 1763431283 -->
- Add developer setup script <!-- backlog: 1763431283 -->
- Create troubleshooting guide for CI failures <!-- backlog: 1763431283 -->



###### Ready


###### In Progress


###### Done

- Update Ruby version matrix (remove 2.3.7, add 3.0, 3.1, 3.2) <!-- backlog: 1763431283, done: 1763432749, ready: 1763432044 -->
- Update `actions/checkout` from v2 to v4 <!-- backlog: 1763431283, in_progress: 1763432783, ready: 1763432091, done: 1763445658 -->
- Update Ruby version matrix (remove 2.3.7, add 3.0, 3.1, 3.2) <!-- backlog: 1763431283, in_progress: 1763432792, ready: 1763432536, done: 1763445658 -->
- Update `actions/checkout` from v2 to v4 <!-- backlog: 1763431283, in_progress: 1763432804, ready: 1763432616, done: 1763445658 -->
- Update `actions/upload-artifact` from v2 to v4 <!-- backlog: 1763431283, in_progress: 1763432865, ready: 1763432104, done: 1763445658 -->
- Update `actions/upload-artifact` from v2 to v4 <!-- backlog: 1763431283, in_progress: 1763432995, ready: 1763432617, done: 1763445658 -->
- Set `PATH_HELPER_DOCKER_INSTANCE=true` environment variable in workflow <!-- backlog: 1763431283, ready: 1763432605, in_progress: 1763433000, done: 1763445658 -->
- Fix `spec/shell_spec.sh:187` - change `return $PASS` to `exit $PASS` <!-- backlog: 1763431283, ready: 1763432613, in_progress: 1763433000, done: 1763445658 -->
- Add `workflow_dispatch` trigger for manual runs <!-- backlog: 1763431283, ready: 1763432619, in_progress: 1763433000, done: 1763445658 -->
- Add concurrency control to prevent duplicate runs <!-- backlog: 1763431283, ready: 1763432621, in_progress: 1763433000, done: 1763445658 -->
- Add explicit permissions declaration <!-- backlog: 1763431283, ready: 1763432623, in_progress: 1763433000, done: 1763445658 -->
- Add job/step timeout configurations <!-- backlog: 1763431283, ready: 1763432624, in_progress: 1763433000, done: 1763445658 -->
- Add APT package caching to speed up builds <!-- backlog: 1763431283, ready: 1763432625, in_progress: 1763433000, done: 1763445658 -->
- Optimize test setup to reduce execution time <!-- backlog: 1763431283, ready: 1763432627, in_progress: 1763433000, done: 1763445658 -->
- Add build matrix fail-fast configuration <!-- backlog: 1763431283, ready: 1763432629, in_progress: 1763433000, done: 1763445658 -->
- Upload test results on both success and failure <!-- backlog: 1763431283, ready: 1763432631, in_progress: 1763433000, done: 1763445658 -->
- Add test result summary to workflow output <!-- backlog: 1763431283, ready: 1763432632, in_progress: 1763433000, done: 1763445658 -->
- Add step to display test failures in readable format <!-- backlog: 1763431283, ready: 1763432634, in_progress: 1763433000, done: 1763445658 -->
- Configure artifact retention period <!-- backlog: 1763431283, ready: 1763432635, in_progress: 1763433000, done: 1763445658 -->
- Document new workflow structure in README <!-- backlog: 1763431283, ready: 1763432636, in_progress: 1763433000, done: 1763445658 -->
- Add contributing guide for CI/CD changes <!-- backlog: 1763431283, ready: 1763432637, in_progress: 1763433000, done: 1763445658 -->
- Document how to run tests locally vs CI <!-- backlog: 1763431283, ready: 1763432638, in_progress: 1763433000, done: 1763445658 -->
- Create `.github/actions/setup-test-env/` composite action <!-- backlog: 1763431283, ready: 1763432644, in_progress: 1763433000, done: 1763445658 -->
- Create `.github/actions/run-shell-tests/` composite action <!-- backlog: 1763431283, ready: 1763432645, in_progress: 1763433000, done: 1763445658 -->
- Fix install script path from `/tmp/install.sh` to `docker/install.sh` Note! This may be because it's built by Packer. Check first! <!-- backlog: 1763431283, in_progress: 1763432947, ready: 1763432611, done: 1763447482 -->
