# path_helper #

A replacement for Apple's `/usr/libexec/path_helper` using a shell script to set the path with the system dirs at the back, e.g. `/bin` and `/usr/bin` etc are last in the path, because if I've installed anything I want it to come first in the path (or why install it?)

Because the string munging is difficult with a shell script I soon became bored fighting a seemingly intractable battle and decided to rewrite it in Ruby, with extra features (see below). It uses the system Ruby on OS X (v2.0) so it should work regardless of whether Ruby has been upgraded or not. I favour the Ruby script, it's better but the shell script will replace Apple's `path_helper` and still be an improvement. Note the slight difference in calling it though.

Additionally, it'll provided `MANPATH`, and the Ruby script with also do `DYLD_FALLBACK_FRAMEWORK_PATH` / `DYLD_LIBRARY_PATH`. 

## Install ##

Run `sudo make` and it will install it.

    $ sudo make
    install -m 0755 ./path_helper /usr/local/libexec/
    install -m 0755 ./path_helper.rb /usr/local/libexec/

Apple's path_helper is in `/usr/libexec`, so the default here is `/usr/local/libexec`, this install won't break anything.

And checking its output:

    $ /usr/local/libexec/path_helper
    PATH="/opt/pkg/sbin:/opt/pkg/bin:/opt/X11/bin:/opt/ImageMagick/bin:/usr/local/MacGPG2/bin:/usr/local/git/bin:/opt/puppetlabs/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"; export PATH;

Or using the Ruby version:

    $ /usr/local/libexec/path_helper.rb

    /Users/yb66/Library/Haskell/bin:/opt/pkg/bin:/opt/pkg/sbin:/usr/local/MacGPG2/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin

The Ruby script doesn't set the path, it returns a path, you have to set the path with it e.g. `PATH=$(/usr/local/libexec/path_helper.rb -p "")`. Call `/usr/local/libexec/path_helper.rb -h` to see all the options.

### Note: ###

The output is just an example, I ran these at different times on different systems so they have slightly different output (aside from the aforementioned slight difference in API).

### ZSH/Bash

We also need to inform `ZSH` or `Bash` about the new `path_helper`. Using the shell version:

    if [ -x /usr/local/libexec/path_helper ]; then
      eval `/usr/local/libexec/path_helper`
    fi

The Ruby version:

    if [ -x /usr/local/libexec/path_helper.rb ]; then
      PATH=$(/usr/local/libexec/path_helper.rb -p "")
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

There's not really any help made for paths that might be local to the user, like `~/.rubies` or something like that so I've added two places the Ruby script will check for further paths, `~/Library/Paths/` and `~/.config/paths/`. The directory layout is the same but if you can't be bothered to use the `paths.d/` subdir then you don't have to, the script will handle it.

The Ruby script will also allow use of the tilde `~` character in a path by replacing it with the `HOME` env variable. For example, I installed Haskell:

    $ tree ~/Library/Paths 
    /Users/iainb/Library/Paths
    ├── paths
    └── paths.d

    $ cat ~/Library/Paths/paths                          
    ~/Library/Haskell/bin

That puts `/Users/iainb/Library/Haskell/bin` at the front of my path and will only apply to my account's `PATH`.

## Man paths and DYLD ##

Apple has already dictated that `/etc/manpath` and `/etc/manpath.d/` are the default paths for setting `MANPATH`, so the same pattern has been followed for that as with `PATH`, so just add `~/Library/Paths/manpath` or `~/.config/paths/manpath` along with the `manpath.d` sub directory if you wish.

Same goes for DYLD (if using the Ruby script), `~/Library/Paths/dyld_path` or `~/.config/paths/dyld_path` (and the `dyld_path.d` sub dir too, if you wish).
