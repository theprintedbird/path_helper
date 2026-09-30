# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A replacement for Apple's `/usr/libexec/path_helper`. It reads path fragments from `paths`/`paths.d` style
files and prints a `:`-joined string on **stdout** — it never `eval`s or exports anything itself. The
caller does `export PATH=$(path_helper -p)`.

There are two implementations of the same CLI:

- `exe/path_helper` — Ruby, a single self-contained script (no `lib/`, no runtime deps, Ruby >= 2.6 --
  the minimum is macOS's own deprecated system Ruby, `/usr/bin/ruby`, since a shell profile runs
  `path_helper` on that Ruby before any version manager has put a newer one on `PATH`).
  The gemspec `require_relative`s it to read `PathHelper::VERSION`.
- `src/path_helper.cr` + `src/path_helper/*.cr` — Crystal port, built with `shards build`.

Both must behave identically: one language-agnostic suite (`spec/shell_spec.sh`) tests whichever binary
`PATH_HELPER_EXECUTABLE` points at. **Any behavioural change must be made in both**, and the version
number lives in two places (`exe/path_helper` `PathHelper::VERSION`, `src/path_helper/version.cr`,
plus `shard.yml`).

## Build and test

Everything runs in a container; the suite is destructive (it writes to and then `rm -rf`s `/etc/*paths*`,
`~/.config/paths`, `~/Library/Paths`) and refuses to run unless `PATH_HELPER_DOCKER_INSTANCE` is set.
Never run `spec/shell_spec.sh` directly on the host with that variable set.

```shell
make test RUBY_VER=3.3            # one Ruby version (2.7, 3.3, 4.0.6; also buildable on demand: 2.6, macOS's system Ruby)
make test-crystal CRYSTAL_VER=1.14.0   # one Crystal version (1.10.1, 1.11.2, 1.14.0, latest)
make test-crystal CRYSTAL_VER=1.14.0 CRYSTAL_LIBC=gnu   # against glibc (Ubuntu base) not musl (Alpine)
make test-all / make test-crystal-all
make all                          # build + test both languages
make shell RUBY_VER=3.3           # interactive container
make coverage RUBY_VER=3.3        # suite with line coverage; report in coverage/ruby/
make coverage-crystal CRYSTAL_VER=1.14.0   # same for Crystal (kcov, always glibc); coverage/crystal/
make coverage-all                 # coverage for every Ruby and Crystal version, each into coverage/ruby-<ver>/ or
                                  # coverage/crystal-<ver>/ (not part of `make all`: slow, builds kcov)
make list / make clean
make check                        # host-only, no container: lint + actionlint; before committing
```

The test/shell/extract targets build their image first, so there is no need to run a build target by
hand. Image tags embed `git describe`, so a new commit invalidates images built earlier.

To run only some test files, name them: `make test RUBY_VER=3.3 TESTS="path error"` (likewise
`test-crystal` and the `-all` targets) passes them to the container's entrypoint, `spec/shell_spec.sh`.
`path`, `path_test`, `path_test.sh` and `spec/tests/path_test.sh` are all accepted; `setup` always runs
first and the files keep their fixed order; an unknown name is a `Bail out!` with exit 1, reported
before the guard. A file is the finest grain — within one, each file is a flat sequence of calls, so to
run a single case comment out the others or invoke the executable by hand inside `make shell`.

The Makefile picks podman or docker, whichever is on `PATH`.

**Coverage** (`spec/lib/coverage/run.sh <ruby|crystal> <report dir> [test file]...`) wraps the suite
rather than changing it: each run of the executable is its own process, so counts are collected per
process and merged by `report.rb` into `summary.md` (per-file lines, %, uncovered line ranges; also
printed as TAP comments after the plan). The exit status is the suite's; there is no gate.
  `report.rb` compares total line coverage with a threshold (`threshold` in `report.rb`: 100, or
  `PATH_HELPER_COVERAGE_THRESHOLD`, which the Makefile passes to the container only when set) and,
  below it, appends `**Warning:** line coverage is X%, below the N% threshold (M lines uncovered).`
  to `summary.md` and prints it on stderr (`run.sh` merges that into the report it prints as TAP
  comments). The run-shell-tests summary step turns it into a `::warning title=Coverage::` annotation.
  Warning only; making it a gate later means changing the exit status.
- Ruby: `ruby_coverage.rb` goes in via `RUBYOPT=-r...` and uses stdlib `Coverage` -- no gem, the
  executable untouched. For a process whose `$0` is `path_helper` it starts `Coverage` and `load`s the
  script itself, since before Ruby 3 `Coverage` ignores the main program; the script's own `exit`
  carries the status out. Everything else (the timing helper's `ruby -e`) is left alone. It must never
  print, raise or change the status -- the suite compares both streams and the exit code.
- Crystal: a `--debug` build (release builds have no line table) run under kcov via a generated wrapper
  script set as `PATH_HELPER_EXECUTABLE`; kcov passes stdout/stderr/status through. kcov is built from
  source by `docker/install-kcov.sh` (not packaged for Ubuntu 24.04 or Alpine; apt only, no musl), so
  `coverage-crystal` uses its own glibc image, `Dockerfile.crystal-coverage`, run with
  `--security-opt seccomp=unconfined` (kcov disables ASLR in the tracee, which the default profile
  refuses). The wrapper always runs the one binary in `$WORK/bin`, so `run.sh` also exports
  `PATH_HELPER_EXECUTABLE_WRAPPED=1` (read only by the harness, not passed to children): a copy of the
  wrapper reports that binary's path, not its own, which `shell_test.sh`'s awkward-directory points
  can't cope with.
- Everything the executable touches is in a world-readable work dir (`/tmp/path_helper-coverage`,
  raw output dir mode 1777, kcov output per uid), because `test_unreadable_fragment` copies the
  executable and runs the copy as *nobody*, who can't read `/root`. That includes kcov: `run.sh`
  runs a copy of it from `$WORK/bin/kcov`, not the installed one, since CI's lives under the runner's
  home, which *nobody* can't traverse (it links only system libraries and writes out its embedded
  helper libraries at run time, so the lone binary copies cleanly).
- `.gitignore` has `/coverage/` anchored: unanchored, it would also ignore `spec/lib/coverage/`.

## Test suite shape

`spec/shell_spec.sh` reports [TAP 14](https://testanything.org/): `ok`/`not ok` lines, a trailing plan,
YAML diagnostic blocks on failure, and diffs/timings as `#` comments (comments rather than YAML block
scalars because diffs contain blank and space-indented lines). Exit status is 0 iff every test point
passed. A missing `PATH_HELPER_DOCKER_INSTANCE` produces `1..0 # SKIP` and exit 0.

`spec/shell_spec.sh` sets `PLATFORM` (`darwin` on macOS, `linux` for any other `uname -s`) before
sourcing the helpers, and reports it as `# Platform:` straight after the version line. It is read from
the OS rather than an env var on purpose: the default search order is fixed by where the executable runs,
so claiming another platform could only make the fixtures disagree. Every expected-output lookup goes
through `fixture_path` in `spec/lib/test_helpers.sh`: `spec/fixtures/$PLATFORM/results/<file>` if it
exists, else the shared `spec/fixtures/results/<file>`. So a platform copy is only needed where the output
differs (the default search order), and the failure YAML's `fixture:` is the path actually compared.

The same `case` sets the user segment the inputs go in — the one the platform searches by default, so no
path test has to switch a segment on: `USER_SEGMENT=config`/`USER_PATHS=.config/paths` with
`OTHER_SEGMENT=lib` on Linux, and `lib`/`Library/Paths` with `config` on macOS (plus `OTHER_PATHS`, the
other segment's directory). Setup is `--setup --$USER_SEGMENT --no-$OTHER_SEGMENT` for the user segment,
then `--setup --$OTHER_SEGMENT --no-$USER_SEGMENT --no-etc` for the other one, which gets its own small
inputs so the `--$OTHER_SEGMENT`/`--no-$OTHER_SEGMENT` tests (and `--no-lib` on Linux) act on a real tree.
It is off by default, so no default-run fixture sees it. The segment-switch tests in `path_test.sh` are
written in those variables; enabling the other segment gives `[user, other, etc]` on both platforms. The
lines found are the same either way, so the plain path fixtures are shared; only the fixtures that name a
home segment's directory have copies in `spec/fixtures/darwin/results/` — the twelve `debug_*` ones (which
also print `Search order:`) and `colons_warning.txt` (the warning names the fragment file). A new fixture
containing `{{HOME}}/.config/paths/` or `{{HOME}}/Library/Paths/` needs a Darwin copy with the two swapped
(and `lib`/`config` swapped in `Options:` and `Search order:`).
Those can only be checked for real on a Mac, because the order comes from `RUBY_PLATFORM` or the Crystal
compile target.

- `spec/lib/test_helpers.sh` — the TAP reporting, `cleanup`, and every assertion (`test_a_path`,
  `expect_failure`, ...). It only defines things; `spec/shell_spec.sh` sources it (located via `$0`),
  holds the guard, and then sources the test files.
- The harness is plain `sh` run by whatever `/bin/sh` is — busybox ash in the Alpine images (which have
  bash and zsh only for `shell_test.sh` to run as children), dash in the glibc Crystal image, bash-as-sh
  on macOS. `local` is the one non-POSIX feature
  used; `spec/shell_spec.sh` bails out on a shell without it. Write `local x="$(...)"`, quoted, since
  `local` isn't an assignment to POSIX and some shells field-split its value.
- macOS's bash-as-sh is also BSD userland: `sed -i`, `stat`, `readlink`, `realpath` and `date +%N` are
  GNU-only and either error out or emit something different there. `mktemp`/`mktemp -d` are fine (BSD
  has had both forms since 10.11). `make lint` (`spec/lint_portability.sh`, plain POSIX sh, no
  `grep -P`) greps the harness files and the actions' `run:` blocks for these forms, skipping comment
  lines since the harness's own comments deliberately mention some of them; it also runs as a CI step
  in `.github/actions/run-shell-tests` before the suite, ahead of the macOS job. `make check` runs
  `make lint` plus `actionlint` over `.github/workflows/` (it and `shellcheck` must be on `PATH`; fails
  with a one-line install hint otherwise -- actionlint quietly skips `run:` scripts without
  shellcheck, and CI's `ubuntu-latest` has it, so a local run without it could pass what CI fails) -- both host-only and fast; jj has no hooks, so run it by hand before
  committing. CI runs the same two checks separately: `lint_portability.sh` in `run-shell-tests`,
  `actionlint` in `.github/workflows/lint.yml`.
- `spec/tests/*_test.sh` — the tests, sourced (not executed, since the TAP counters are shell globals)
  in this order: `setup_test.sh` (`--setup` of both home segments, and the symlinks, dangling link,
  subdirectory and fifo every later file relies on — so it must stay first — then a `--dry-run` in a
  scratch `HOME`), `path_test.sh` (each env var plain and `--debug`, the `DEBUG` env var, colour on a
  terminal, the `--etc`/`--no-*` segment switches, enabling the other segment, append mode),
  `error_test.sh` (exit status and stream contract: refusals, `--setup` without permission, `--`,
  `--version`, `--help`), `edge_case_test.sh` (awkward input files), `case_test.sh` (names differing
  only by case), `shell_test.sh` (the output used by real shells). Nothing after setup mutates shared
  state (the dry run, the permission tests, `case_test.sh` and `shell_test.sh` use scratch `HOME`s),
  so the last five can be reordered freely. The order is
  `TEST_FILES` in `spec/shell_spec.sh`, which is also what named files are checked against, so a new
  test file has to be added there.
- `--setup` without permission runs as *nobody* (`as_nobody`, like `test_unreadable_fragment`) in a
  scratch `HOME` whose segment root is root's, once with the `.d` directories there and once without.
  It compares the whole permissions report byte for byte, built in the test from `$root` and
  `$SETUP_NAMES` (Setup::ENV_VARS order, directory then file per var) rather than a fixture, since a
  fixture naming the user segment's path would need a Darwin copy (`USER_PATHS` differs by platform).
  It also asserts exit non-zero, nothing created (directories included, when they were the ones
  missing), and stdout empty.
- Colour: both implementations take their colours from `tput` only when stdout is a TTY, so every
  fixture is plain. `test_colour_on_a_terminal` runs `-p --debug` on a pseudo-terminal via `script`
  (`pty_flavour` probes for util-linux/busybox `-c` or BSD syntax) with `TERM=xterm` and compares the
  `Name:` line with one built from `tput`; without `script` or `tput` it emits `ok ... # SKIP`
  (`tap_skip`). The Alpine Dockerfiles `apk add util-linux ncurses` for it; CI's Alpine jobs skip.
  (They also `apk add bash zsh`, and the glibc images `apt-get install zsh`, for `shell_test.sh`.)
- `test_a_path_with_env` adds one `NAME=value` to the run's environment through `env(1)` (a prefix
  assignment on a function call may outlive it in POSIX sh); the `DEBUG` test uses it.
- `case_test.sh` probes the file system (`is_case_insensitive`, a scratch file looked up in the other
  case) rather than trusting `PLATFORM`, reports the result as `# File system:`, and expects whichever
  outcome that file system should give — so its case-insensitive branch only runs on a Mac (macOS CI).
  It works in a scratch `HOME` and compares strings built in the test (`test_path_under_home`,
  `test_files_listed_under_home`), not fixtures. Being non-destructive, it can be run on a Mac host by
  sourcing `spec/lib/test_helpers.sh` and the test file with `EXECUTABLE`, `PLATFORM=darwin` and
  `USER_PATHS=Library/Paths` set — without the guard variable.
- `shell_test.sh` runs the output through `sh` (whatever `/bin/sh` is, reported as `# sh is:`), `bash`
  and `zsh`, four points each, a shell that isn't installed giving `# SKIP <shell> not installed`.
  Each runs as a profile would (`run_in_shell`: `env -i` with `HOME`, a built `PATH` of ruby's
  directory plus `/usr/bin:/bin`, `EXE`, `RUBY`; `bash --norc --noprofile`, `zsh -f`) in a scratch
  `HOME` whose user segment names a directory with a space in it, holding a probe program. It checks
  that `export PATH=$("$EXE" -p "$PATH" --no-etc)` exports exactly what `-p` prints, that
  `command -v` then finds the probe there and runs it, and that the `--setup --dry-run` snippet,
  sourced, exports every variable it names with the value its switch prints directly. One shell-less point
  and one per shell do the same for a snippet made with `--$OTHER_SEGMENT --no-etc` (given in that order, the other
  segment holding a directory of its own): its export lines must end `--no-etc --$OTHER_SEGMENT` (the fixed
  etc/lib/config order `Setup` emits segment switches in), and sourced it must export what each switch prints with
  those segment switches. A fourth point sources the snippet of a *copy* of the
  executable in a directory named with spaces and quotes (`it's a "tricky" dir`), and one shell-less
  point checks the `if [ -x ... ]` line is the POSIX single-quoted path (`'` written `'\''`, in both
  implementations; Ruby's lines are `$(ruby 'PATH' switch)`, Crystal's `$('PATH' switch)`). What was
  exported is read back by a child, a Ruby script (`write_env_reporter`) rather than `env(1)`: macOS
  strips `DYLD_*` from its protected binaries' environment, so there those are left out of the check
  when the only ruby is the system one. Under Crystal coverage (`PATH_HELPER_EXECUTABLE_WRAPPED` set)
  the `-x` point and the three awkward-directory per-shell points are `tap_skip`ped, since a copy of
  kcov's wrapper still runs the fixed binary and names its path; the point count is unchanged. Like
  `case_test.sh`, it can be run on a Mac host.
- `spec/fixtures/moredirs/` — input path files, copied by the run into the platform's user segment:
  `~/.config/paths` on Linux, `~/Library/Paths` on macOS.
- `spec/fixtures/otherdirs/` — the other segment's inputs (a `paths`, one `paths.d` fragment and a
  `manpaths`), copied into `~/Library/Paths` on Linux and `~/.config/paths` on macOS. A few lines repeat
  ones in the user and etc segments, to show where the segment falls in the search order.
- `spec/fixtures/results/*.txt` — expected stdout, byte-compared with `cmp`. The home directory is
  stored as the placeholder `{{HOME}}`, substituted at compare time; a literal `$HOME` in a fixture is
  intentional — it comes from an input file and must survive to the output verbatim.
- Byte-comparison makes whitespace load-bearing: the plain path fixtures end **without** a trailing
  newline (the executable emits none), the `--debug` ones end with one, and `dyld-fram.txt`/`dyld-lib.txt`
  are legitimately empty. An editor that "helpfully" adds a final newline will break `cmp`.
- Debug output is compared too (`debug_path.txt`, `debug_pkg_config.txt`), which is why the Crystal
  `Debug#format_options` deliberately reproduces Ruby 3.4's `Hash#inspect` format and Ruby's
  `format_options` hand-rolls it rather than calling `inspect`.
- `--version` and `--help` go to **stderr**, exit 0, and must leave stdout empty — stdout carries the
  path. Help is checked for switch coverage by regex, not by fixture, since the two option parsers
  render switches differently (`--[no-]etc` vs `--etc`/`--no-etc`).
- No arguments at all is an error (exit 1); `-h` is not.

## Container/CI layout

`Dockerfile.ruby` and `Dockerfile.crystal` copy the project to `/tmp`, run `docker/install*.sh` to lay
things out under `/root`, set `PATH_HELPER_DOCKER_INSTANCE` and `ENTRYPOINT ["spec/shell_spec.sh"]`.

Each Dockerfile sets `PATH_HELPER_EXECUTABLE` to name the implementation under test —
`/root/exe/path_helper` for Ruby, `/root/bin/path_helper` for Crystal. That matters for the Crystal
image, which also installs Ruby (the suite's timing helper shells out to `ruby`) and keeps the Ruby
script at `/root/exe/path_helper`: without the variable the suite's default of `$PWD/exe/path_helper`
would silently test Ruby instead. CI installs the suite and the implementation under test in root's
home — `~root/exe/path_helper` whatever the language, `/root` on Linux and `/var/root` on macOS —
via `.github/actions/setup-test-env`, and that action's `executable` and `home` outputs are passed
into `run-shell-tests`, which runs the suite as root with `HOME` and `PATH_HELPER_EXECUTABLE` set. Both
actions are POSIX `sh` with no package manager, and use `sudo` only when not already root, so the same
steps run on a hosted Ubuntu or macOS runner and in a root container job without sudo or bash (Alpine).
`sudo` drops the environment, so the variables (and `PATH`, for the tool-cache Ruby) are handed over
through `env(1)` rather than exported around it. The suite does its own `--setup`, so the actions don't.

CI: `.github/workflows/test-ruby.yml` (Ruby matrix) and `test-crystal.yml`, both driving the two
composite actions in `.github/actions/`. They run on `master` and `dev`, path-filtered to what each
reads (a YAML anchor shared by `push` and `pull_request`): Ruby on `exe/**`, Crystal on `src/**`,
`shard.yml`/`shard.lock` and `docker/install-kcov.sh`, both on `spec/**`, `docker/assets/**`,
`.github/actions/**` and their own workflow file. A new file either run reads must be added to its
list, or a change to it alone won't be tested. Each has an
`ubuntu-latest`/`macos-latest` matrix job and an Alpine container job -- `test-ruby-alpine` in
`ruby:<ver>-alpine`, `test-crystal-alpine` in `crystallang/crystal:<ver>-alpine` (which `apk add`s
ruby) -- since `ruby/setup-ruby` and `crystal-lang/install-crystal` have no Alpine builds. So CI tests
Crystal against glibc on Ubuntu and musl on Alpine, as `CRYSTAL_LIBC` does locally.
Both Alpine jobs `apk add bash zsh` for `shell_test.sh`. `ubuntu-latest` has bash but not zsh, and
deliberately gets no apt step for it: zsh on Linux is already covered by the Alpine jobs, so the
Ubuntu jobs' zsh points skip; macOS has both.
Each workflow also has one coverage job on `ubuntu-latest` (`coverage-ruby`, Ruby 3.3;
`coverage-crystal`, Crystal latest, which installs kcov first -- built from source into
`KCOV_PREFIX` under `$HOME` and cached across runs by `actions/cache`, keyed on the kcov version
(`KCOV_VERSION`, the job's one source of truth for it), the runner OS/arch/Ubuntu release and
`docker/install-kcov.sh` itself; on a hit whose `kcov --version` runs, `install-kcov.sh` does nothing
(not even `apt-get update`), otherwise it installs only kcov's runtime libraries, and rebuilds if the
binary is missing or still doesn't run):
`run-shell-tests` takes a `coverage:
ruby|crystal` input that runs `spec/lib/coverage/run.sh` instead of the suite, appends `summary.md` to
the job summary and exposes the report dir as the `coverage-dir` output for the artifact upload.

Every Crystal job in `test-crystal.yml` caches `crystal env CRYSTAL_CACHE_DIR` (the compiler's own
cache, not the binary) with `actions/cache/restore` before the build and `actions/cache/save` straight
after it, under an exact key: OS, arch, a `cksum` of the full `crystal --version` (so `latest` and
each libc target get their own) and `hashFiles('src/**', 'shard.yml')`. The compiler still parses,
type-checks, generates IR and links; it reuses the cached `.o` only if the IR is byte-identical, so a
hit only skips LLVM's `--release` optimisation and can't change what is tested. A `--release` build
is one LLVM module, so a stale entry can never be partly reused -- hence no `restore-keys`.
`coverage-crystal` only restores (its throwaway release build shares test-crystal's ubuntu/latest
key). The Alpine job `apk add`s GNU `tar`, which `actions/cache` needs. `release.yml` deliberately
uses no cache, so shipped binaries never come from a cache entry.

A fourth workflow, `.github/workflows/lint.yml`, runs on `.github/**` changes only: it downloads a
pinned, checksum-verified `actionlint` release and runs it over the four workflows (and the two
composite actions, as far as a workflow references them). Third-party actions across all four
workflows (anything not under `actions/`) are pinned to a full commit SHA with a trailing `# vX.Y.Z`
comment naming the release it resolves to; Dependabot proposes updates to both. `actions/*` stays on its major tag.

## Core logic (mirrored in both implementations)

`CLI#run` is a four-step pipeline: determine the search graph → find files → read them → join.

- **Search order** (`Helpers.determine_search_order`): macOS defaults to `[:lib, :config, :etc]`,
  other unixes to `[:config, :lib, :etc]`. The *second* entry is dropped unless explicitly enabled —
  so `~/.config/paths` is off by default on a Mac and `~/Library/Paths` is off elsewhere, each turned on
  with `--config`/`--lib`. Any segment can be removed with `--no-*`.
- **Sections** (`Helpers.create_section`): the env var name is downcased and pluralised to derive both
  the directory (`<name>s.d`) and the file (`<name>s`) under each segment root — e.g. `MANPATH` →
  `manpaths.d`/`manpaths`. Adding a new env var means adding it to `Setup::ENV_VARS` and a switch.
- **De-duplication and order**: `all_lines` is an insertion-ordered hash used as a set, so first
  occurrence wins. Directory entries are read in sorted filename order (hence the numeric prefixes),
  then the plain file for that segment. Segments are processed in search order, which is the whole point
  of the project: user paths land *before* the system ones.
- **Current path**: the argument to `-p` etc. is appended after the generated segments, de-duplicated
  against them and `~`-expanded like any other line, so `export PATH=$(path_helper -p "$PATH")` keeps
  the old path behind the new one. With no argument -- or an empty one -- nothing is appended: every
  path switch always sets `:current_path` (to `nil` when its argument is absent or empty, in both
  implementations), so `CLI#initialize` reads `options[:current_path]` directly and there is no `ENV`
  fallback to fall back to. `path-appended.txt`/`manpath-appended.txt` cover appending;
  `debug_path.txt` covers `nil` (an empty argument prints identically to no argument at all).
- `~` in a path line is expanded to `HOME` only at the final join step.
- **Invalid switches**: both parsers are wrapped so an unknown switch prints `Invalid option: <switch>`
  and `See --help for available options.` on stderr and exits 1. The wording is fixture-compared, so
  Ruby spells the first line out by hand rather than using `ex.message` (`invalid option:`, lowercase).
  The two stdlib parsers also disagree about the *optional* argument the path switches take: Ruby's
  refuses any `-`-prefixed token, Crystal's swallows one unless it is a registered flag, so
  `PathHelper.path_argument` rejects it to keep `-p -z` an error in both. A lone `-` is refused too, in
  both implementations, with the same `Unexpected argument: -` wording as the leftover-argument guard:
  Ruby's own optparse disagrees with itself about it across the versions this project tests --
  2.6/2.7/3.0/3.1 leave it in ARGV, caught by the leftover-argument guard, while 3.2/3.3/4.0 offer it as
  the argument, so Ruby's `normalize_path` raises the same `Unexpected argument` error there, sharing
  its wording with the guard via the `unexpected_argument` proc. Crystal's `path_argument` raises a
  dedicated `UnexpectedArgument` exception for it, rescued alongside `InvalidOption` in `run` and
  printing the same message. See the comment above `PathHelper.path_argument` in `src/path_helper.cr`.

## Docs and planning

`README.md` is the user-facing manual and also documents the dev workflow — keep it in step with
Makefile targets and test output changes. `CHANGES.md` is the changelog, `ROADMAP.md` and
`TODO.kanban.md`/`testing-list.md` track CI and test-coverage work in progress.

## Version control

The repo is a colocated jj/git checkout (`.jj` and `.git`); work through jj.
