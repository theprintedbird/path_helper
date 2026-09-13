# Darwin fixtures

Expected output for a run on macOS, where it differs from Linux.

The default search order is fixed by the platform:  `RUBY_PLATFORM` for Ruby,
the compile target for Crystal. It can't be overridden, so these can only be
checked on a Mac (the `macos-latest` CI jobs):

- macOS: `[:lib, :config, :etc]`, `~/.config/paths` off unless `--config`
- Linux: `[:config, :lib, :etc]`, `~/Library/Paths` off unless `--lib`

The input files (`moredirs`, `linkeddir`, `linkedfile`) are the same on all
platforms, so only `results/` is split. On macOS, they are copied into
`~/Library/Paths`, the user segment a Mac searches by default. The lines found
are therefore the same as on Linux and the path fixtures stay shared. Only
fixtures that name the user segment's directory differ, so every shared fixture
containing `{{HOME}}/.config/paths/` has a version with `{{HOME}}/Library/Paths/`
instead - the `--debug` ones, which also print `Search order: [:lib, :etc]`,
and `colons_warning.txt`, whose warning names the fragment file.

`results/` follows the conventions of `spec/fixtures/results/`: same file names;
`{{HOME}}` for the home directory; and whitespace byte-compared. On macOS, the
suite looks first in the `darwin/results` dir, with the shared files as fallback.
Only fixtures whose output differs on a Mac belong in this directory.
