# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A replacement for Apple's `/usr/libexec/path_helper`. It reads path fragments from `paths`/`paths.d` style
files and prints a `:`-joined string on **stdout** — it never `eval`s or exports anything itself. The
caller does `export PATH=$(path_helper -p)`.

There are two implementations of the same CLI:

- `exe/path_helper` — Ruby, a single self-contained script (no `lib/`, no runtime deps, Ruby >= 2.7).
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
make test RUBY_VER=3.3            # one Ruby version (2.7, 3.3, 4.0.6)
make test-crystal CRYSTAL_VER=1.14.0   # one Crystal version (1.10.1, 1.11.2, 1.14.0, latest)
make test-all / make test-crystal-all
make all                          # build + test both languages
make shell RUBY_VER=3.3           # interactive container
make list / make clean
```

The test/shell/extract targets build their image first, so there is no need to run a build target by
hand. Image tags embed `git describe`, so a new commit invalidates images built earlier.

There is no single-test runner: the suite is a flat sequence of calls at the bottom of
`spec/shell_spec.sh`. To run one case, comment out the others or invoke the executable by hand inside
`make shell`.

The Makefile picks podman or docker, whichever is on `PATH`.

## Test suite shape

`spec/shell_spec.sh` reports [TAP 14](https://testanything.org/): `ok`/`not ok` lines, a trailing plan,
YAML diagnostic blocks on failure, and diffs/timings as `#` comments (comments rather than YAML block
scalars because diffs contain blank and space-indented lines). Exit status is 0 iff every test point
passed. A missing `PATH_HELPER_DOCKER_INSTANCE` produces `1..0 # SKIP` and exit 0.

- `spec/lib/test_helpers.sh` — the TAP reporting, `cleanup`, and every assertion (`test_a_path`,
  `expect_failure`, ...). It only defines things; `spec/shell_spec.sh` sources it (located via `$0`)
  and holds the guard and the run itself.
- `spec/fixtures/moredirs/` — input path files, copied into `~/.config/paths` by the run.
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
would silently test Ruby instead. CI installs the implementation under test at `/root/exe/path_helper`
whatever the language (`.github/actions/setup-test-env`), and that action's `executable` output is
passed into `run-shell-tests`, which sets `PATH_HELPER_EXECUTABLE` for both the `--setup` call and the
suite — `sudo` drops the environment, so the value is named inside each `sudo bash -c` string rather
than exported around it.

CI: `.github/workflows/test-ruby.yml` (Ruby matrix) and `test-crystal.yml`, both driving the two
composite actions in `.github/actions/`. They run on `master` and `dev`.

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
  the old path behind the new one. With no argument -- or an empty one -- nothing is appended: the
  switch always sets `:current_path`, so the `ENV[name]` fallback in both `CLI#initialize`s is
  unreachable from the CLI. `path-appended.txt`/`manpath-appended.txt` cover this.
- `~` in a path line is expanded to `HOME` only at the final join step.
- **Invalid switches**: both parsers are wrapped so an unknown switch prints `Invalid option: <switch>`
  and `See --help for available options.` on stderr and exits 1. The wording is fixture-compared, so
  Ruby spells the first line out by hand rather than using `ex.message` (`invalid option:`, lowercase).
  The two stdlib parsers also disagree about the *optional* argument the path switches take: Ruby's
  refuses any `-`-prefixed token, Crystal's swallows one unless it is a registered flag, so
  `PathHelper.path_argument` rejects it to keep `-p -z` an error in both.

## Docs and planning

`README.md` is the user-facing manual and also documents the dev workflow — keep it in step with
Makefile targets and test output changes. `CHANGES.md` is the changelog, `ROADMAP.md` and
`TODO.kanban.md`/`testing-list.md` track CI and test-coverage work in progress.

## Version control

The repo is a colocated jj/git checkout (`.jj` and `.git`); work through jj.
