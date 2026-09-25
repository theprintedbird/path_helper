# CHANGES #

## Friday the 25th of September 2026 ##

### Code coverage (development only)

- `make coverage RUBY_VER=<ver>` and `make coverage-crystal CRYSTAL_VER=<ver>`
  run the shell suite with line coverage of the implementation under test and
  write a report to `coverage/ruby/` or `coverage/crystal/`: a Markdown
  summary (per-file percentage and the uncovered line numbers), plus a
  SimpleCov-style `.resultset.json` and annotated source for Ruby, and kcov's
  HTML and Cobertura output for Crystal. Ruby uses the standard library's
  `Coverage` loaded through `RUBYOPT` (no gem, nothing in `exe/path_helper`,
  works back to 2.6); Crystal runs a debug build under kcov, which is built
  from source and so is glibc only. Nothing changes for a plain `make test`.
- CI gained a `coverage-ruby` (Ruby 3.3) and a `coverage-crystal` (Crystal
  latest) job on `ubuntu-latest`, which put the summary in the job summary and
  upload the report as an artifact. There is no minimum yet, so coverage never
  fails the build.
- As of this change the suite covers 93.5% of the Ruby script's lines and
  93.6% of the Crystal sources'.

### Ruby minimum lowered to 2.6

- Tested against macOS's system Ruby (`/usr/bin/ruby`, 2.6.10p210, deprecated
  by Apple but still what a shell profile finds before any Ruby version
  manager has put a newer one on `PATH`). The full suite passes unchanged, so
  `spec.required_ruby_version` is lowered from `>= 2.7` to `>= 2.6` and
  `make test RUBY_VER=2.6` is a supported (if not default) target, built from
  `ruby:2.6-alpine3.15` -- the same patch level as macOS ships. CI gained a
  `macos-latest` Ruby job that runs the suite against `/usr/bin/ruby`
  directly rather than a `ruby/setup-ruby`-installed version, to catch a
  future macOS Ruby bump for real.

### dev_only: Dropped redundant setup from `docker/install-ruby.sh`

- `docker/install-ruby.sh` no longer runs `--setup --no-lib` and copies the
  fixtures into `~/.config/paths` at image build time. `spec/tests/setup_test.sh`
  already does both -- for both home segments -- when the suite runs, and its
  own cleanup `rm -rf`s the trees afterwards anyway, so the build-time copy was
  dead weight. `docker/install-crystal.sh` already omitted this step;
  `install-ruby.sh` now ends with the same closing note.

## Tuesday the 8th of September 2026 ##

### v5.0.0

- **Breaking:** `--dyld-fram` and `--dyld-lib` now mean `DYLD_FRAMEWORK_PATH` and
  `DYLD_LIBRARY_PATH`, the vars whose names they actually read as. The fallback
  vars they used to mean have moved to `--dyld-fallback-fram` and
  `--dyld-fallback-lib`; the `-f` and `-l` short forms are unchanged and still
  mean the fallback vars.
- Added support for `DYLD_FRAMEWORK_PATH` and `DYLD_LIBRARY_PATH`, read from
  `dyld_framework_paths{,.d}` and `dyld_library_paths{,.d}` under each segment.
- Fixed `--setup`, which emitted `path_helper -pc` for `PKG_CONFIG_PATH`. That
  parses as `-p` with the argument `c`, so the generated snippet set
  `PKG_CONFIG_PATH` to the PATH with `c` appended. It is `--pc` now.
- Fixed blank lines in a path file, which were read as components. An empty
  line joined into the output as a stray `::`, and a `::` in `PATH` means the
  current working directory -- so a fragment with one newline too many put
  whatever directory you happened to be in on your path. Blank lines are now
  dropped as the files are read, so they reach neither the output nor the
  `--debug` report. A line of nothing but spaces or tabs counts as blank too;
  it is not empty once the newline is stripped, so it used to survive as a
  component named after whitespace. Only wholly blank lines go: a line with a
  path in it keeps the whitespace around that path, since a path may contain
  spaces.
- A line in a path file that contains a colon is now dropped as the file is
  read, and reported on stderr (silenced by `--quiet`) so it can be fixed. A
  colon is the separator the output is joined with, so such a line was never
  one component: it reached the path as two that nothing had de-duplicated,
  and neither of which the `--debug` report had ever seen. The dropped line is
  still shown in the `--debug` tree, marked with a red `⊘` and the reason, so
  the report remains a full account of what was read.
- Fixed the README, which documented the fallback DYLD vars as living in
  `dyld_library_paths` and `dyld_framework_paths`. Those are now the names of
  the *non*-fallback sections, so anyone who followed the old instructions
  should either rename their files to `dyld_fallback_*` or start using the new
  switches to read them.
- Fixed `~` expansion, which replaced every tilde in the output with the home
  directory -- so `/opt/app~1/bin` became `/opt/app/home/you1/bin`, and `~~` was
  expanded twice. A tilde is now expanded only at the front of a component,
  when it is the whole component or is followed by a `/`. `~user` is left as it
  is rather than becoming the home directory followed by `user`.
- An argument that no switch takes is now refused with `Unexpected argument:`
  on stderr and exit status 1. It used to be ignored: the path switches only
  take the token straight after them, so `path_helper -p --no-etc "$PATH"`
  built a path with the old one silently left off. Put the path directly after
  the switch, e.g. `path_helper --no-etc -p "$PATH"`.
- Fixed the Crystal build refusing `--` straight after a path switch with
  `Invalid option: --`. It now ends the options there, as the Ruby script
  always has.
- Fixed a fragment file that cannot be read -- one with the wrong mode, say --
  taking the whole run down with a `Permission denied` error, which left
  `export PATH=$(path_helper -p)` with nothing to export. It is now passed over
  like any other entry that is not a file.
- Fixed the `--debug` report marking everything in a `paths.d` that it did not
  read as `does not exist!`. That is now kept for what really is missing, such
  as a dangling symlink; a subdirectory is marked `is a directory!`, a named pipe
  or other special file `is not a regular file!`, and a file that cannot be read
  `is not readable!`.
- Fixed the `--debug` report for a run given a path to append, such as
  `path_helper -p "$PATH" --debug`, which listed the argument as
  `current path - does not exist!` and left out its components. They are now
  listed under `current path`, after everything the search found, with any
  that the search had already found marked as duplicates.


## Tuesday the 19th of May 2020 ##

### v3.0.0

- No need for those debugging tools to be part of the project now.
- Added a set up switch to make it easier to get going.
- Moved the lib into the one script file, the Ruby ecosystem won't actually be helpful.
- Updated the Makefile for the new project layout and abilities.
- Added support for `PKG_CONFIG_PATH`


## Friday the 26th of January 2018 ##

### v2.3.0 ##

- Added support for `C_INCLUDE_PATH`.

----


### v2.2.0 ##

- Added support for DYLD paths.
- Fixed the -v option that had been doubled up.
- Fixed a bug when no argument passed to --path.

----


### v2.1.0 ##

- Added --version option.

----


## v2.0.0 Thursday the 25th of January 2018 ##

- Added a Ruby script that has more features.
  It can handle per user paths too.
- Updated the Makefile and docs.
- Tidied up the shell script with help from
  https://codereview.stackexchange.com/questions/157450/a-replacement-for-osxs-path-helper

----

