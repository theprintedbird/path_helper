# TODO
<!-- kanban:config persist_card_ids: true -->

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
- `ruby` required for tests (used by the timing helper in `spec/lib/test_helpers.sh`)
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
- Create `ci.yml` main workflow (orchestrator) <!-- backlog: 1763431283, id: card_01M2CH88BK8P0N1F94FVJM60KR -->
- Design workflow structure for Go implementation <!-- backlog: 1763431283, id: card_01M2CH87XDQS1TEBK3KMJEW430 -->
- Create template for adding new language implementations <!-- backlog: 1763431283, id: card_01M2CH88402BTT1FQ104Q58W2G -->
- Document multi-language testing strategy <!-- backlog: 1763431283, id: card_01M2CH88QSMR810X034C596ZRA -->
- Add shell integration tests (bash, zsh, sh) <!-- backlog: 1763431283, id: card_01M2CH88R1KG5HKTC38PM972ZY -->
- Add edge case tests for path handling <!-- backlog: 1763431283, id: card_01M2CH87X5K13N2NP5YXCXEY0A -->
- Add validation tests for setup command <!-- backlog: 1763431283, id: card_01M2CH88116ECZ55A7HQBC6ANT -->
- Implement `test-go.yml` workflow (when Go implementation exists) <!-- backlog: 1763431283, id: card_01M2CH87Y7YD0YB6R6775QFA1Q -->
- Add cross-language compatibility tests <!-- backlog: 1763431283, id: card_01M2CH88T3GY3PJ8JV9F1K9PSW -->
- Add performance comparison between implementations <!-- backlog: 1763431283, id: card_01M2CH8809ACKC836KVWQM91AG -->
- Add test result reporting with PR comments <!-- backlog: 1763431283, id: card_01M2CH88EHJRC4FXWBN7YA6MJG -->
- Add performance benchmarking workflow <!-- backlog: 1763431283, id: card_01M2CH887P2B0TDX1TD7VSZXR1 -->
- Add automated release creation on version tags <!-- backlog: 1763431283, id: card_01M2CH87XFQNCWZ62699QS1CAA -->
- Add dependency vulnerability scanning <!-- backlog: 1763431283, id: card_01M2CH8832E559EMWVVRTHZ4SK -->
- Add SAST (static analysis security testing) <!-- backlog: 1763431283, id: card_01M2CH87ZJEYVC2FYFV6WY084Y -->
- Add workflow security best practices audit <!-- backlog: 1763431283, id: card_01M2CH88T8BY7W1N6F3YTETFZN -->
- Add automated dependency updates (Dependabot) <!-- backlog: 1763431283, id: card_01M2CH88150PJWM0KRN0QF0Z3T -->
- Add local GitHub Actions testing setup (act) <!-- backlog: 1763431283, id: card_01M2CH88Q5F2B115JG0M64TCVQ -->
- Add pre-commit hooks for common issues <!-- backlog: 1763431283, id: card_01M2CH8815F0KQKJZ13PVMBNRW -->
- Add developer setup script <!-- backlog: 1763431283, id: card_01M2CH88NS11S3SD2VRS29MAWV -->
- Add automated changelog generation <!-- id: card_01M2CH87XM5GEB37EGFC1Z945V, ready: 1788877330 -->
- Add golden file generation mode via `GENERATE_GOLDEN` environment variable <!-- backlog: 1789267516, id: card_01M2CH884TEX2CZP8RM345J89Z -->
- Decide: de-duplication compares lines as text, so on case-insensitive APFS `/opt/Foo/bin` and `/opt/foo/bin` (the same directory) both reach PATH. Leave as is (matches `/opt/x` vs `/opt/x/`), or compare case-insensitively where the file system is? <!-- backlog: 1790322957, id: card_01M3BS0QN2BEE4J9NCXXA5X0PV -->
- Decide: `paths.d` fragments sort by byte, so any upper-case name runs before every lower-case one (`10-Zeta` before `10-alpha`). Keep byte order (pinned by spec/tests/case_test.sh), or sort case-insensitively like Finder? <!-- backlog: 1790322957, id: card_01M3BS0QJ769Z62N5M02998RA4 -->
- Coverage threshold: print a non-blocking warning when line coverage drops below a minimum (e.g. 90%) in `make coverage`/`make coverage-crystal` and the CI coverage jobs; later turn it into a gate <!-- backlog: 1790332754, id: card_01M3C2BPC4C1QR07EEQP8SA7RY -->
- Test the lines coverage shows as never run: the `DEBUG` env var, `--setup` permission errors, Crystal's separate `--etc` handler, and colour output under a TTY <!-- backlog: 1790332758, id: card_01M3C2BT7X9ER0AZSR778637SF -->
- Cache the kcov build in the CI `coverage-crystal` job (it is built from source, adding ~1-2 minutes) <!-- backlog: 1790332761, id: card_01M3C2BXSKXZVVDFPCN3KVHE1E -->
- Add a `coverage-all` make target (every Ruby and Crystal version), or fold the coverage targets into `make all` <!-- backlog: 1790332765, id: card_01M3C2C1FN2VCDEJQ9Z1SEN9ZQ -->

###### Ready






###### In Progress









###### Done

- Add code coverage tracking (per language) <!-- backlog: 1763431283, done: 1790332458, id: card_01M2CH882Z08M7FHEVZPTDVKG3, in_progress: 1790327249, ready: 1790327129 -->
- docker/install-ruby.sh still runs --setup --no-lib and copies fixtures into ~/.config/paths when the image is built. Remove redundant code. <!-- backlog: 1789455144, done: 1790327633, id: card_01M2HXD5ZVEAV13ASBJNXV2SG7, in_progress: 1790327249, ready: 1790327097 -->
- Run the suite in CI on ubuntu-latest, alpine and macOS-latest (was: Add tests for different OS environments (Ubuntu, Alpine, macOS)) <!-- backlog: 1763431283, depends_on: [card_01M2CH8809WEBW5WDVMC6D6J70], done: 1789470571, id: card_01M2CH881VFZB6Y03HGZ0RX4F5, in_progress: 1789277287, ready: 1789267594 -->
- Runtime/arch: build and test Crystal against musl (Alpine) and glibc (Ubuntu) <!-- done: 1789470328, id: card_01M2CH88J9PYY3GFP6VG1CQPRE, in_progress: 1789380873, ready: 1789268873 -->
- Harness portability: make `spec/shell_spec.sh` and `spec/lib/test_helpers.sh` run under busybox `sh` on Alpine, or install bash in the image and document it <!-- done: 1789461968, id: card_01M2CH88RNFB00Z6B0FFHAWZMQ, in_progress: 1789380861, ready: 1789268873 -->
- Add test for paths with special characters <!-- done: 1788943142, id: card_01M2CH8832TWQYBBCAG99M3DAA, in_progress: 1788937966, ready: 1788854437 -->
- Add test for paths with spaces <!-- done: 1788937142, id: card_01M2CH88ACQXXNP4KP3VPDGQ8X, in_progress: 1788936901, ready: 1788854437 -->
- Add test for Windows line endings (CRLF) <!-- done: 1788936567, id: card_01M2CH88BJ8THSJ9X5QE149TBW, in_progress: 1788936410, ready: 1788854437 -->
- Add test for files with trailing newlines <!-- done: 1788928504, id: card_01M2CH883HP9N76T0FMQQ5NBKX, in_progress: 1788928303, ready: 1788854437 -->
- Add test for paths with colons (edge case for separator) <!-- done: 1788917566, id: card_01M2CH8816GWB03VY8F1H9DHVA, in_progress: 1788914611, ready: 1788854437 -->
- Add test for files with blank lines <!-- done: 1788875846, id: card_01M2CH88ABR4FJNR6AVY7YRXEG, in_progress: 1788875279, ready: 1788854437 -->
- Add empty input file handling test <!-- done: 1788854673, id: card_01M2CH88R5QPWN9T6RNE67P3C5, in_progress: 1788854512, ready: 1788854437 -->
- Add debug output tests for all 6 path types (currently only 2) <!-- backlog: 1788767641, done: 1788771000, id: card_01M2CH888FDA95N5DC8JD8EYZG, in_progress: 1788769867, ready: 1788768220 -->
- Add append mode tests (`-p $PATH`) <!-- backlog: 1788767620, done: 1788769004, id: card_01M2CH88SQYDRPKWEVT0RE1V63, in_progress: 1788768758, ready: 1788768217 -->
- Add tests for all flag combinations (`--no-etc`, `--no-config`, `--no-lib`) <!-- backlog: 1788767542, done: 1788768412, id: card_01M2CH88NPC7PFS6BQ7BS6C5T9, in_progress: 1788768212 -->
- Add test for missing required arguments <!-- backlog: 1788767523, done: 1788767827, id: card_01M2CH88D1210M93XGWGH0D2XJ, in_progress: 1788767703 -->
- Add test for invalid flag handling <!-- done: 1788763175, id: card_01M2CH88TC9XGD1W5HAV9H5P1R, in_progress: 1788762156 -->
- Add `--version` output test <!-- done: 1788744786, id: card_01M2CH88E3PK5WCCBYM3V1F1Q4, ready: 1788744552 -->
- Add `-h/--help` output test <!-- done: 1788744786, id: card_01M2CH88HF45ZA4A62P7WJVJ2S, ready: 1788744564 -->
- Update Ruby version matrix (remove 2.3.7, add 3.0, 3.1, 3.2) <!-- backlog: 1763431283, done: 1763432749, id: card_01M2CH88PXXXCY6GNKG47DMJCF, ready: 1763432044 -->
- Update `actions/checkout` from v2 to v4 <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88CYN5W18BRR3QZ6D55R, in_progress: 1763432783, ready: 1763432091 -->
- Update `actions/checkout` from v2 to v4 <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH87X7ZPEJXK55RAY05AYF, in_progress: 1763432804, ready: 1763432616 -->
- Update `actions/upload-artifact` from v2 to v4 <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88GS3BHWARNNA5C32E0W, in_progress: 1763432865, ready: 1763432104 -->
- Set `PATH_HELPER_DOCKER_INSTANCE=true` environment variable in workflow <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH880ZNMHDE01W84TYJB3Q, in_progress: 1763433000, ready: 1763432605 -->
- Fix `spec/shell_spec.sh:187` - change `return $PASS` to `exit $PASS` <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88AC9XK3TFV82137YGS3, in_progress: 1763433000, ready: 1763432613 -->
- Add `workflow_dispatch` trigger for manual runs <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH8829BKMCEHW8H51JNMV7, in_progress: 1763433000, ready: 1763432619 -->
- Add concurrency control to prevent duplicate runs <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88B4JP5FDTQ4Z7TJFEZG, in_progress: 1763433000, ready: 1763432621 -->
- Add explicit permissions declaration <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88MYYYHMRZP6QYR75R7F, in_progress: 1763433000, ready: 1763432623 -->
- Add job/step timeout configurations <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH87X41407NPJJ5GEZ1S0N, in_progress: 1763433000, ready: 1763432624 -->
- Add APT package caching to speed up builds <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88SNYZCQRAQ85RNQ1MED, in_progress: 1763433000, ready: 1763432625 -->
- Optimize test setup to reduce execution time <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88FCQTGGWC2S8CCA68GS, in_progress: 1763433000, ready: 1763432627 -->
- Add build matrix fail-fast configuration <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88PGBRGFQBBJXBJE1779, in_progress: 1763433000, ready: 1763432629 -->
- Upload test results on both success and failure <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH8869C928V1VKP5ZDVYNS, in_progress: 1763433000, ready: 1763432631 -->
- Add test result summary to workflow output <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88PJQX1DMS1NZHTMRS5Z, in_progress: 1763433000, ready: 1763432632 -->
- Add step to display test failures in readable format <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH886BPZQ60TDSTF2DKJ79, in_progress: 1763433000, ready: 1763432634 -->
- Configure artifact retention period <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88KW0BHN8GQS26AGWDGC, in_progress: 1763433000, ready: 1763432635 -->
- Document new workflow structure in README <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH8830ZNV3FD5NKSAZCX5T, in_progress: 1763433000, ready: 1763432636 -->
- Add contributing guide for CI/CD changes <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88PR980GSDSWAWZAT1TJ, in_progress: 1763433000, ready: 1763432637 -->
- Document how to run tests locally vs CI <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH88W4QQZGRFMEJP0ZWVTT, in_progress: 1763433000, ready: 1763432638 -->
- Create `.github/actions/setup-test-env/` composite action <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH881S4AHJYM7APMVSJ946, in_progress: 1763433000, ready: 1763432644 -->
- Create `.github/actions/run-shell-tests/` composite action <!-- backlog: 1763431283, done: 1763445658, id: card_01M2CH8868DQPGF8SF9EKABQPZ, in_progress: 1763433000, ready: 1763432645 -->
- Fix install script path from `/tmp/install.sh` to `docker/install.sh` Note! This may be because it's built by Packer. Check first! <!-- backlog: 1763431283, done: 1763447482, id: card_01M2CH88H3M6CY1CYYXNDM410N, in_progress: 1763432947, ready: 1763432611 -->
- Create `.github/actions/setup-test-env/` composite action <!-- backlog: 1763431283, done: 1788509104, id: card_01M2CH887VX6DPVYESWHF68M3C -->
- Create `.github/actions/run-shell-tests/` composite action <!-- backlog: 1763431283, done: 1788509108, id: card_01M2CH8864PVW4FJKHP4CSDBKV -->
- Extract common test setup logic from workflow <!-- backlog: 1763431283, done: 1788583697, id: card_01M2CH87Z9BBR8CAYMK22JB7SP -->
- Create reusable test execution wrapper <!-- backlog: 1763431283, done: 1788583703, id: card_01M2CH88V4JCP94KYHXWGE2DAE -->
- Implement `test-crystal.yml` workflow (when Crystal implementation exists) <!-- backlog: 1763431283, done: 1788742321, id: card_01M2CH88GA4MX437Y3H4D98P8Q -->
- Design workflow structure for Crystal implementation <!-- backlog: 1763431283, done: 1788742328, id: card_01M2CH87ZQEXH7H7XCDAC55MV6 -->
- Add workflow for release automation <!-- backlog: 1763431283, done: 1788742334, id: card_01M2CH88H4HT0JPCYXMD2B843P -->
- Add workflow for testing Docker builds <!-- backlog: 1763431283, done: 1788742337, id: card_01M2CH88V1DTDNR1MNZQ27EP80 -->
- Adopt TAP for tests. <!-- backlog: 1788744353, done: 1788744362, id: card_01M2CH87YGHZYJECGW2CVH2HH9 -->
- Create/rename current path helper workflow to `test-ruby.yml` (language-specific) <!-- backlog: 1763431283, done: 1788757196, id: card_01M2CH87YVXAEMKZHQJ6H6JPPV -->
- Create troubleshooting guide for CI failures <!-- backlog: 1763431283, done: 1788767633, id: card_01M2CH88FVFZE1Y0CP920XM9NT -->
- Bug fix and test - a whitespace-only line ("   ") is not empty?, so it currently becomes a real path component. <!-- backlog: 1788938049, done: 1788942837, id: card_01M2CH8816SEAK4K145G24PR25, in_progress: 1788938105 -->
- Add test for Unicode characters in paths <!-- done: 1788964234, id: card_01M2CH87YRTJD56YSHA319P9MM, in_progress: 1788950362, ready: 1788854437 -->
- Add test for non-existent paths in path files <!-- done: 1788964286, id: card_01M2CH88N3M3JTE9RDGWQG9T23, in_progress: 1788950412, ready: 1788854437 -->
- Add test for symlinked directories <!-- done: 1788964386, id: card_01M2CH88CD1QNJ8MMR4V1G9RZ9, in_progress: 1788950452, ready: 1788854437 -->
- Add test for symlinked path files <!-- done: 1788964446, id: card_01M2CH88VD2AFNJS8SXGDS3JNV, in_progress: 1788950494, ready: 1788854437 -->
- Add test for `$HOME` expansion <!-- done: 1788964613, id: card_01M2CH888CY1S3MM36VF8ZPP2S, in_progress: 1788950526, ready: 1788854437 -->
- Add test for `~` expansion at various positions <!-- done: 1788964686, id: card_01M2CH88JDZ18QR8GENZ955832, in_progress: 1788950568, ready: 1788854437 -->
- Add test for duplicate paths across files <!-- done: 1788965413, id: card_01M2CH888TPJBT6BEF9JD6QAWH, in_progress: 1788950591, ready: 1788854437 -->
- Add test for duplicate paths in same file <!-- done: 1788965493, id: card_01M2CH88W69HG5SR3879MDHQ7R, in_progress: 1788950608, ready: 1788854437 -->
- Fix ~ is expanded anywhere in a component, not just at the front <!-- backlog: 1788965755, done: 1789025216, id: card_01M2CH88DTHCVPN3M4P5EDKHRW, in_progress: 1789022129 -->
- Fix: A stray positional argument is silently ignored e.g. path_helper -p --no-etc /some/path <!-- backlog: 1788965769, done: 1789031085, id: card_01M2CH881MCMC87EKQD0ATFE0B, in_progress: 1789025343 -->
- Fix The debug report prints <path> - does not exist! for anything in paths.d that isn't a readable file. <!-- backlog: 1788965784, done: 1789044100, id: card_01M2CH88RYE168T8G7BF2RA3H1, in_progress: 1789031177 -->
- Fix crashing on fragment file <!-- backlog: 1789044137, done: 1789044670, id: card_01M2CH88T8CZBEDVYZKXG4T57C, in_progress: 1789044159 -->
- Update main runner to source and execute modular test files <!-- done: 1789112839, id: card_01M2CH88T67VE5MD3YES1PNKZT, in_progress: 1789097244 -->
- Create `spec/lib/test_helpers.sh` with common functions <!-- done: 1789112904, id: card_01M2CH883E3ZPDN8MXJFFM15EW, in_progress: 1789097066, ready: 1789096800 -->
- Split tests into modular files under `spec/tests/` <!-- done: 1789112927, id: card_01M2CH8842DD3BFTPY8RFJFMGT, in_progress: 1789097066, ready: 1789096800 -->
- Update the test runner to allow test names as arguments for single-test runs <!-- done: 1789112976, id: card_01M2CH88CQNN55QSWQ04DXR3NS, ready: 1789097636 -->
- Make `run-shell-tests`/`setup-test-env` work on macOS runners and in an Alpine container. They currently assume Ubuntu with sudo: `apt-get install bc`, everything under `/root` via `sudo bash -c` (so a Mac would test root's home, not `/Users/runner`), no `sudo`/`bash` in Alpine, `crystal-lang/install-crystal` has no Alpine support (use a `crystallang/crystal:*-alpine` image), and `/etc` is `/private/etc` on macOS. `ci.yml` is not a prerequisite: add an OS matrix axis to `test-ruby.yml`/`test-crystal.yml` now and fold them into `ci.yml` later <!-- done: 1789277153, id: card_01M2CH8809WEBW5WDVMC6D6J70, in_progress: 1789274797, ready: 1789268873 -->
- Create `spec/fixtures/darwin/` directory structure <!-- backlog: 1789267653, done: 1789279506, id: card_01M2CH88DZABAN9WV2F6SP2QE3, in_progress: 1789279322, ready: 1789267708 -->
- Add platform detection to test runner <!-- backlog: 1789267681, done: 1789279943, id: card_01M2CH88PH5DDPKSSMG4E3NYG0, ready: 1789267727 -->
- Create macOS-specific fixtures with Library paths <!-- backlog: 1789267671, done: 1789297640, id: card_01M2CH88K67Q43ZZHX7NS1RP0Q, ready: 1789267720 -->
- Add a `macOS-latest` job to `test-ruby.yml` and `test-crystal.yml` (the only place the Darwin fixtures get checked, since the default search order comes from `RUBY_PLATFORM`/the compile target and can't be overridden) <!-- depends_on: [card_01M2CH8809WEBW5WDVMC6D6J70], done: 1789380656, id: card_01M2CH88W6TF6BFGHE9P7V29N9, in_progress: 1789277274, ready: 1789268873 -->
- Note: No longer needed, uses shared fixtures. Move current fixtures to linux subdirectory <!-- backlog: 1789267661, done: 1789380803, id: card_01M2CH8854KA6470A5P2WZS37B, ready: 1789267711 -->
- macOS file-system: check `/etc` and `/tmp` being symlinks to `/private/...` doesn't change debug output or the "does not exist" report <!-- done: 1789380895, id: card_01M2CH882ZS1F9W6DAB8452976, ready: 1789268873 -->
- macOS file-system: check the Unicode path test and `paths.d` sort order survive Unicode normalisation of filenames (NFC vs NFD) <!-- done: 1789380899, id: card_01M2CH88SFE3YTZVTKKXG331RG, ready: 1789268873 -->
- Home directory: verify `{{HOME}}` substitution, `--setup` output and `~` expansion with `/Users/<name>` (macOS), `/home/runner` (CI) and `/root` (Docker) <!-- done: 1789380905, id: card_01M2CH88W08FP1P0TD81PHZ54Z, ready: 1789268873 -->
- Note: No longer needed, uses shared fixtures - Create `spec/fixtures/linux/` directory structure <!-- backlog: 1789267643, done: 1789454747, id: card_01M2CH880XFA4B8JBWCFD3VVH1, in_progress: 1789449476, ready: 1789267705 -->
- Note: no longer needed, covered by card_01M2CH88B8M17GETM9TZ5VHC10. Test the default search order per OS: macOS `[:lib, :config, :etc]` (config off unless `--config`), Linux `[:config, :lib, :etc]` (lib off unless `--lib`) <!-- done: 1789454992, id: card_01M2CH88QEBJCFBBT4WEGH01WN, in_progress: 1789449527, ready: 1789268873 -->
- Update fixture paths to use platform-specific directories <!-- backlog: 1789267692, done: 1789455396, id: card_01M2CH887AHC847CEJG31F71PK, in_progress: 1789449543, ready: 1789267729 -->
- Runtime/arch: run the suite on arm64 as well as x86_64 (`macOS-latest` is arm64) <!-- done: 1789525949, id: card_01M2CH88S8XTPFHA0M94SRY0T4, ready: 1789268873 -->
- Harness portability: check up front for the `ruby` the timing helper needs and `Bail out!` if missing; `bc` no longer appears in `spec/`, so drop it from `setup-test-env` and the Dependencies note if it's truly unused <!-- done: 1789606098, id: card_01M2CH87XSSB7Q55VS049H5ATH, in_progress: 1789525983, ready: 1789455429 -->
- macOS file-system: test case-insensitive APFS name clashes (e.g. `Paths` vs `paths`, `paths.d` entries differing only by case) <!-- done: 1790322874, id: card_01M2CH889WK0DNQW99H11YZYA7, in_progress: 1790322047, ready: 1789268873 -->
- Test `--lib`/`--config` enabling the second segment on each OS, and `--no-lib` against a real `~/Library/Paths` (covers the backlog item "--no-lib coverage needs `~/Library/Paths`") <!-- done: 1790323207, id: card_01M2CH88B8M17GETM9TZ5VHC10, in_progress: 1790322048, ready: 1789455435 -->
- --no-lib coverage needs `~/Library/Paths` to be set up <!-- backlog: 1788768670, done: 1790323207, id: card_01M2CH8870QGWRFJ4VHNA0D2KS -->
- Harness portability: check the suite on BSD userland (macOS) — `mktemp`/`mktemp -d` are used today; keep `sed -i`, `stat`, `readlink` and `date +%N` out <!-- done: 1790323360, id: card_01M2CH88J3N85JJYVK4EYAFYFB, in_progress: 1790322048, ready: 1789268873 -->
- Runtime/arch: test against the old system Ruby shipped with macOS, or document the minimum Ruby supported there <!-- done: 1790323465, id: card_01M2CH88R4CMWBQ65KGX13PC38, in_progress: 1790322048, ready: 1789268873 -->
