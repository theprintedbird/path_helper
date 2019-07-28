# path_helper

## WHAT?

A replacement for Apple's `/usr/libexec/path_helper`.

## WHAT DOES THAT DO?

It helps set the PATH environment variable.

## WHY REPLACE IT?

Because Apple's one loads the system libraries to the front, which almost certainly isn't what you want.

## WHAT ELSE DOES IT DO?

I'm glad you asked. Apple has some good ideas (lots of them, actually) that developers overlook for whatever reason. One of them is the way path_helper works. By putting the paths in well known locations (e.g. /etc/paths and /etc/paths.d/*) it's easy to create a PATH that works for you. This library extends that to:

MANPATH  
C_INCLUDE_PATH  
DYLD_FALLBACK_FRAMEWORK_PATH  
DYLD_FALLBACK_LIBRARY_PATH  

and of course, PATH.

## DO I NEED TO BE ON APPLE TO USE IT?

No, it should work on any unix system.

## Install ##

Run `sudo make` and it will install it.

    $ sudo make
    install -m 0755 ./path_helper /usr/local/libexec/

Apple's path_helper is in `/usr/libexec`, so the default here is `/usr/local/libexec`, this install won't break anything.

And checking its output:

    $ /usr/local/libexec/path_helper
    PATH="/opt/pkg/sbin:/opt/pkg/bin:/opt/X11/bin:/opt/ImageMagick/bin:/usr/local/MacGPG2/bin:/usr/local/git/bin:/opt/puppetlabs/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"; export PATH;


The script doesn't set the PATH, it returns a path, you have to set the path with it e.g. `PATH=$(/usr/local/libexec/path_helper.rb -p "")`. Call `/usr/local/libexec/path_helper -h` to see all the options.

### Note: ###

The output is just an example, I ran these at different times on different systems so they have slightly different output (aside from the aforementioned slight difference in API).

### ZSH/Bash

We also need to inform `ZSH` or `Bash` about the new `path_helper`. Using the shell version:

    if [ -x /usr/local/libexec/path_helper ]; then
      eval `/usr/local/libexec/path_helper`
    fi

The Ruby version:

    if [ -x /usr/local/libexec/path_helper.rb ]; then
      PATH=$(/usr/local/libexec/path_helper.rb -p)
    fi

The `Makefile` will print out what needs to go in, if you change any of the settings.

## Source Files ##

Apple has put paths in `/etc/paths` and further files are there for the user or apps to add under `/etc/paths.d/`. If you want to order them then prefixing a number works well, e.g.

    $ tree /etc/paths.d
    /etc/paths.d
    ├── 10-pkgsrc
    └── MacGPG2
    └── ImageMagick

The format of the file is simply a path per line, e.g.

    $ cat /etc/paths.d/10-pkgsrc
    /opt/pkg/bin
    /opt/pkg/sbin

    $ cat /etc/paths            
    /usr/local/bin
    /usr/local/sbin
    /usr/bin
    /usr/sbin
    /bin
    /sbin

### Note: ###

The `/etc/paths` file in Apple isn't set out fully or in the order I'd want so I changed mine, you may want to do the same.


## Per user paths ##

This is the bit I like best.

There's not really any help made for paths that might be local to the user, like `~/.rubies` or something like that so I've added two places the Ruby script will check for further paths, `~/Library/Paths/` and `~/.config/paths/`. The directory layout is the same but if you can't be bothered to use the `paths.d/` subdir then you don't have to, the script will handle it.

The Ruby script will also allow use of the tilde `~` character in a path by replacing it with the `HOME` env variable. For example, I installed Haskell:

    $ tree ~/Library/Paths 
    /Users/iainb/Library/Paths
    ├── paths
    └── paths.d

    $ cat ~/Library/Paths/paths                          
    ~/Library/Haskell/bin

That puts `/Users/iainb/Library/Haskell/bin` at the front of my path and will only apply to my account's `PATH`.

The order of per user paths shouldn't be that important as they'll all go before the system ones but `~/Library/Paths` will be checked first as it's more Mac-ish.

## Man paths and DYLD and C_INCLUDE ##

### Manpaths

Apple has already dictated that `/etc/manpath` and `/etc/manpath.d/` are the default paths for setting `MANPATH`, so the same pattern has been followed for that as with `PATH`, so just add `~/Library/Paths/manpath` or `~/.config/paths/manpath` along with the `manpath.d` sub directory if you wish.

- `/etc/manpaths.d/`
- `/etc/manpaths`
- `~/Library/Paths/manpath`
- `~/.config/paths/manpath`

(and the `dyld_path.d` sub dir too, for the last two if you wish).


### DYLD ###

Same goes for DYLD_FALLBACK_LIBRARY_PATH and DYLD_FALLBACK_FRAMEWORK_PATH (if using the Ruby script):

- `/etc/dyld_library_paths.d/`
- `/etc/dyld_library_paths`
- `~/Library/Paths/dyld_library_path`
- `~/.config/paths/dyld_library_path`

and:

- `/etc/dyld_framework_paths.d/`
- `/etc/dyld_framework_paths`
- `~/Library/Paths/dyld_framework_path`
- `~/.config/paths/dyld_framework_path` 

(and the corresponding `dyld_NAME_path.d` sub dir too, for the last two if you wish).


### C_INCLUDE ###

Same again for `C_INCLUDE`:

- `/etc/include_paths.d/`
- `/etc/include_paths`
- `~/Library/Paths/include_path`
- `~/.config/paths/include_path`

(and the `include_path.d` sub dir too, for the last two if you wish).


## Development

I'm happy to hear from you, email me or open an issue. Pull requests are fine too, try to bring me a spec or an example if you want a feature or find a bug.

Sorry the current specs aren't in such good shape, I hope to improve that.

## Licence

See the LICENCE file.

