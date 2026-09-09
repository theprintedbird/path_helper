# CHANGES #

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

