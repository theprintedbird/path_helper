# path_helper

## WHAT?

A replacement for Apple's `/usr/libexec/path_helper`.

## WHAT DOES THAT DO?

It helps set the PATH environment variable, among other things.

## WHY REPLACE IT?

Because Apple's one loads the system libraries to the front, which almost certainly isn't what you want. Have a look:

    $ /usr/libexec/path_helper
    PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
    <snip!>

## WHAT ELSE DOES IT DO?

I'm glad you asked. Apple has some good ideas (lots of them, actually) that developers overlook for whatever reason. One of them is the [*framework bundle structures*](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/FrameworkAnatomy.html), but more on that in a moment.

Apple's `path_helper` helps organise the `PATH` and `MANPATH` by listing things you want added to the path in text files in well known locations (e.g. /etc/paths and /etc/paths.d/*) it's easy to create a PATH that works for you. Where the Apple `path_helper` falls down is:

- It puts them in /etc meaning you need elevated permissions
- Being in /etc also makes them system wide
- It's only for `PATH` and `MANPATH` but development and administration often need new installs' headers and libraries accessible in the same way too
- The string it returns is designed to be `eval`'d. I know that `eval` isn't *always* evil but why not just return the `PATH` string and allow it to be set to a variable - maybe there's more to be added? Just a thought.

This library fixes those problems by extending that to:
  
    C_INCLUDE_PATH  
    DYLD_FALLBACK_FRAMEWORK_PATH  
    DYLD_FALLBACK_LIBRARY_PATH  
    PKG_CONFIG_PATH

and of course, `PATH` and `MANPATH`.

## DO I NEED TO BE ON APPLE TO USE IT?

No, it should work on any unix-like system.

## HOW DOES PATH_HELPER KNOW WHAT TO PUT IN THE PATH?

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


The order *within* the file matters as well as the order the files are read/concatenated.

### Note: ###

The `/etc/paths` file in Apple isn't set out fully or in the order I'd want so I changed mine, you may want to do the same.


## Per user paths ##

This is the bit I like best.

There's not really any help made for paths that might be local to the user, like `~/.rubies` or something like that so I've added two places the Ruby script will check for further paths:

- `~/Library/Paths/paths.d` and `~/Library/Paths/paths`, and 
- `~/.config/paths.d/` and `~/.config/paths`

You can use the `--setup` to have the path_helper set up the directory layout and files, you just have to fill them!

The Ruby script will also allow use of the tilde `~` character in a path by replacing it with the `HOME` env variable. For example, if I install Haskell and want to put it in my path I can do the following.

### Way 1, Use the paths, Luke

    $ echo '~/Library/Haskell/bin' > ~/Library/Paths/paths

    $ tree ~/Library/Paths 
    /Users/iainb/Library/Paths
    ├── paths
    └── paths.d

    $ cat ~/Library/Paths/paths                          
    ~/Library/Haskell/bin

That puts `/Users/iainb/Library/Haskell/bin` at the front of my path and will only apply to my account's `PATH`.

### Way 2, paths.d/

    $ touch ~/Library/Paths/paths.d/60-Haskell

    $ tree ~/Library/Paths 
    /Users/iainb/Library/Paths
    ├── paths
    └── paths.d
        └── 60-Haskell


#### Why use the paths.d sub directory?

If I show you my actual set up it'll become clearer:

    $ tree ~/Library/Paths 
    /Users/iainb/Library/Paths
    ├── paths
    └── paths.d
        ├── 05-pkgsrc
        ├── 08-homebrew
        ├── 10-keybase
        ├── 30-oh-my-zshell
        ├── 50-ngrok
        ├── 55-Crystal-opt
        ├── 60-Crystal
        ├── 61-Opam
        ├── 62-Haskell
        ├── 63-Erlang
        ├── 63-Go
        ├── 64-Pyenv
        ├── 65-Rust
        └── 66-Antigen

Once you start installing various things it make sense to keep their paths in their own file, it's easier to organise (and remove).

## The order


    Library/Paths/paths.d ordered as the file system does
    Library/Paths/paths
    .config/paths.d (same again)
    .config/paths
    /etc/paths.d (same again)
    /etc/paths

## Why Library/Paths/paths and not Library/paths ?

Because this is such a useful pattern that I've extended it for headers and includes, read on!

## Man paths and DYLD and C_INCLUDE and PKG_CONFIG ##

### Manpaths

Apple has already dictated that `/etc/manpaths` and `/etc/manpaths.d/` are the default paths for setting `MANPATH`, so the same pattern has been followed for that as with `PATH`, so just add `~/Library/Paths/manpaths` or `~/.config/manpaths` along with the `manpaths.d` sub directory if you wish.

- `~/Library/Paths/manpaths.d/`
- `~/.config/manpaths`
- `~/Library/Paths/manpaths.d/`
- `~/.config/manpaths`
- `/etc/manpaths.d/`
- `/etc/manpaths`


### DYLD ###

Same goes for DYLD_FALLBACK_LIBRARY_PATH and DYLD_FALLBACK_FRAMEWORK_PATH (if using the Ruby script):

- `~/Library/Paths/dyld_library_paths.d/`
- `~/.config/dyld_library_paths`
- `~/Library/Paths/dyld_library_paths.d/`
- `~/.config/dyld_library_paths`
- `/etc/dyld_library_paths.d/`
- `/etc/dyld_library_paths`

and:

- `~/Library/Paths/dyld_framework_paths.d/`
- `~/.config/dyld_framework_paths` 
- `~/Library/Paths/dyld_framework_paths.d/`
- `~/.config/dyld_framework_paths` 
- `/etc/dyld_framework_paths.d/`
- `/etc/dyld_framework_paths`


### C_INCLUDE ###

Same again for `C_INCLUDE`:

- `~/Library/Paths/include_paths.d/`
- `~/Library/Paths/include_paths`
- `~/.config/include_paths.d/`
- `~/.config/include_paths`
- `/etc/include_paths.d/`
- `/etc/include_paths`

(and the `include_paths.d` sub dir too, for the last two if you wish).

### PKG_CONFIG_PATH

Did you know that there's a `PKG_CONFIG_PATH`? There is, check the man page.

- `~/Library/Paths/pkg_config_paths.d/`
- `~/Library/Paths/pkg_config_paths`
- `~/.config/pkg_config_paths.d/`
- `~/.config/pkg_config_paths`
- `/etc/pkg_config_paths.d/`
- `/etc/pkg_config_paths`

## HOW DO I GET THIS WONDERFUL JOYFUL EVENT MAKER INTO MY LIFE? ##

I was going to make this into a Ruby gem but that is such a faff. Here's the gist of it:

- Download it (use `git clone` or a download link, you can even just copy and past the [script](exe/path_helper))
- Make sure it has the correct permissions (`chmod +x`)
- Have a look at the help by running it with `-h`.
- Run the `--setup` (take note of the `--lib` and `--config` and their `--no-` counterparts)
- Copy and paste the bit setup tells you to, and put it in your `~/.zshenv` or `~/.bashenv`
- Find your life is so much better now it's easy to manage your paths

For example:

I put my path_helper in `/usr/local/libexec` because I'm the only person using this machine and I want my other accounts to be able to access its goodness but you can put it anywhere you like.

    sudo mkdir -p /usr/local/libexec
    cd /usr/local/libexec

`~/Projects/path_helper` is where I keep the project so I link it, but you could just download it or `git clone` it there, or somewhere else and link it… it all works!

    ln ~/Projects/path_helper/exe/path_helper .
    chmod +x /usr/local/libexec/path_helper

Look at the help because you're not like everyone else, you read instructions ;-)

    /usr/local/libexec/path_helper --help

You need sudo to add the folders in /etc, see the --help if you don't want that.

    sudo /usr/local/libexec/path_helper --setup

See what's already there

    /usr/local/libexec/path_helper --debug


Apple's path_helper is in `/usr/libexec`, this install won't touch it, you can always use it or return to it if you wish.

And checking its output:

    $ /usr/local/libexec/path_helper -p
    /opt/pkg/sbin:/opt/pkg/bin:/opt/X11/bin:/opt/ImageMagick/bin:/usr/local/MacGPG2/bin:/usr/local/git/bin:/opt/puppetlabs/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"
    
To put it into the PATH via the command line:

    $ PATH=$(/usr/local/libexec/path_helper -p)
    $ export PATH

but you'll probably use the helpful `--setup` instructions.

## NOTE!

Remember, the script **doesn't set the PATH**, it *returns* a path, **you have to set the path** with it e.g. `PATH=$(/usr/local/libexec/path_helper.rb -p "")`. Call `/usr/local/libexec/path_helper -h` to see all the options.


## My actual system

This is how my PATH var is set:

    $ tree ~/Library/Paths 
    /Users/iainb/Library/Paths
    ├── c_include_paths
    ├── c_include_paths.d
    │   ├── 03-bdwgc
    │   ├── 04-llvm
    │   ├── 05-gcc7
    │   ├── 06-gcc48
    │   ├── libiconv
    │   └── zig
    ├── dyld_framework_paths
    ├── dyld_framework_paths.d
    ├── dyld_library_paths
    ├── dyld_library_paths.d
    │   ├── 04-llvm
    │   ├── 05-gcc7
    │   ├── 06-gcc48
    │   ├── 61-Opam-and-OCaml
    │   └── libiconv
    ├── manpaths
    ├── manpaths.d
    │   ├── 02-fzf
    │   ├── 04-llvm
    │   ├── 04-pkgin
    │   ├── 05-macports
    │   └── 61-Opam-and-OCaml
    ├── paths
    ├── paths.d
    │   ├── 02-fzf
    │   ├── 03-libiconv
    │   ├── 04-llvm
    │   ├── 05-pkgsrc
    │   ├── 10-keybase
    │   ├── 50-ngrok
    │   ├── 55-Crystal-opt
    │   ├── 60-Crystal
    │   ├── 61-Opam-and-OCaml
    │   ├── 62-Haskell
    │   ├── 63-Erlang
    │   ├── 63-Go
    │   ├── 64-Pyenv
    │   ├── 65-Rust
    │   ├── 66-Antigen
    │   ├── 67-Lua
    │   ├── 68-Zig
    │   ├── 70-perl
    │   ├── docker-scripts
    │   └── gcc
    └── pkg_config_paths.d
        ├── from-crystal
        ├── libiconv
        ├── openssl
        └── readline

    $ tree /etc/paths.d/
    /etc/paths.d/
    ├── 10-BitKeeper
    ├── 10-pkgsrc
    ├── 15-macports
    ├── 20-XCode
    ├── MacGPG2
    ├── dotnet
    ├── dotnet-cli-tools
    ├── go
    ├── mono-commands
    └── workbooks

    if [ -x "/path/to/path_helper" ]; then
      PATH=$(ruby "/path/to/path_helper" -p 2>/dev/null)
    fi
    export PATH

### In fact

While I've been redeveloping this, I've been using this in my `~/.zshenv`:

    # see https://github.com/yb66/path_helper
    if [ -x "${HOME}/bin/path_helper" ]; then
      PATH=$(ruby "${HOME}/bin/path_helper" -p 2>/dev/null)
      DYLD_FALLBACK_FRAMEWORK_PATH=$(ruby "${HOME}/bin/path_helper" --dyld-fram 2>/dev/null)
      DYLD_FALLBACK_LIBRARY_PATH=$(ruby "${HOME}/bin/path_helper" --dyld-lib  2>/dev/null)
      C_INCLUDE_PATH=$(ruby "${HOME}/bin/path_helper" -c 2>/dev/null)
      MANPATH=$(ruby "${HOME}/bin/path_helper" -m 2>/dev/null)
      # Pkgconfig is underrated for getting things to compile.
      PKG_CONFIG_PATH=$(ruby "${HOME}/bin/path_helper" --pc 2>/dev/null)
    fi
    export PATH
    export DYLD_FALLBACK_FRAMEWORK_PATH
    export DYLD_FALLBACK_LIBRARY_PATH
    export C_INCLUDE_PATH
    export MANPATH
    export PKG_CONFIG_PATH

Those `2>/dev/null` are because the Ruby team decided to spam us with warnings about everything. Thanks, Ruby core team!


## You know what else is helpful?

The `--debug` flag. For example:

    $ exe/path_helper -p --debug           
    Name: PATH
    Options: {:name=>"PATH", :current_path=>nil, :debug=>true, :verbose=>true}
    Search order: [:config, :etc]
      /root/.config/paths/paths.d
      /root/.config/paths/paths
      /etc/paths.d
      /etc/paths

    Results: (duplicates marked by ✗)

    /root/.config/paths/paths.d/03-libiconv
     └── ~/Library/Frameworks/Libiconv.framework/Versions/Current/bin
    /root/.config/paths/paths.d/04-llvm
     ├── /opt/local/libexec/llvm-11/bin
     ├── /opt/pkg/bin
     └── ~/Library/Frameworks/LLVM.framework/Programs
    /root/.config/paths/paths.d/05-pkgsrc
     ├── /opt/pkg/bin ✗
     ├── /opt/pkg/sbin
     └── /opt/pkg/gnu/bin
    /root/.config/paths/paths.d/10-keybase
     ├── $HOME/gopath
     └── $HOME/gopath/bin
    /root/.config/paths/paths.d/30-oh-my-zshell
     └── ~/.oh-my-zsh/custom/plugins/fzf/bin
    /root/.config/paths/paths.d/50-ngrok
     └── ~/Applications/ngrok
    /root/.config/paths/paths.d/55-Crystal-opt
     ├── /opt/crystal/bin
     └── /opt/crystal/embedded/bin
    /root/.config/paths/paths.d/60-Crystal
     ├── ~/Library/Frameworks/Crystal.framework/Versions/Current/bin
     └── ~/Library/Frameworks/Crystal.framework/Versions/Current/embedded/bin
    /root/.config/paths/paths.d/61-Opam-and-OCaml
     ├── ~/Library/Frameworks/Opam.framework/Programs
     ├── ~/.opam/4.10.0/bin
     └── ~/.opam/4.10.0/sbin
    /root/.config/paths/paths.d/62-Haskell
     └── ~/Library/Haskell/bin
    /root/.config/paths/paths.d/63-Erlang
     └── ~/Library/Frameworks/Erlang.framework/Programs
    /root/.config/paths/paths.d/63-Go
     └── ~/go/bin
    /root/.config/paths/paths.d/64-Pyenv
     └── ~/.pyenv/bin
    /root/.config/paths/paths.d/65-Rust
     └── ~/.cargo/bin
    /root/.config/paths/paths.d/66-Antigen
     └── ~/bin
    /root/.config/paths/paths.d/67-Lua
     └── ~/.lua/bin
    /root/.config/paths/paths.d/68-Zig
     └── ~/Library/Frameworks/Zig.framework/Programs
    /root/.config/paths/paths.d/docker-scripts
     └── ~/Projects/ThePrintedBird/scripts/docker
    /root/.config/paths/paths.d/gcc
     ├── /opt/pkg/gcc7/bin
     └── /opt/pkg/gcc48/bin
    /root/.config/paths/paths
     └── /opt/local/sbin
    /etc/paths

    Env var:
    /root/Library/Frameworks/Libiconv.framework/Versions/Current/bin:/opt/local/libexec/llvm-11/bin:/opt/pkg/bin:/root/Library/Frameworks/LLVM.framework/Programs:/opt/pkg/sbin:/opt/pkg/gnu/bin:$HOME/gopath:$HOME/gopath/bin:/root/.oh-my-zsh/custom/plugins/fzf/bin:/root/Applications/ngrok:/opt/crystal/bin:/opt/crystal/embedded/bin:/root/Library/Frameworks/Crystal.framework/Versions/Current/bin:/root/Library/Frameworks/Crystal.framework/Versions/Current/embedded/bin:/root/Library/Frameworks/Opam.framework/Programs:/root/.opam/4.10.0/bin:/root/.opam/4.10.0/sbin:/root/Library/Haskell/bin:/root/Library/Frameworks/Erlang.framework/Programs:/root/go/bin:/root/.pyenv/bin:/root/.cargo/bin:/root/bin:/root/.lua/bin:/root/Library/Frameworks/Zig.framework/Programs:/root/Projects/ThePrintedBird/scripts/docker:/opt/pkg/gcc7/bin:/opt/pkg/gcc48/bin:/opt/local/sbin


Everything you need to know! Very useful for working out when other things are manipulating the path too.

## Development

I'm happy to hear from you, email me or open an issue. Pull requests are fine too, try to bring me a spec or an example if you want a feature or find a bug.

### To get set up for development

Run:

    docker build --squash -t path_helper .

and I tend to get rid of the intermediate layers:

    docker images --no-trunc -aqf "dangling=true" | xargs docker rmi

### To run the specs

Shell in and have a play:

    docker run --rm -ti -v "$PWD":/root path_helper sh

    ./exe/path_helper --setup --no-lib
    ./spec/shell_spec.sh
    ./exe/path_helper -p
    ./exe/path_helper -c
    ./exe/path_helper -f
    ./exe/path_helper -l
    ./exe/path_helper -m
    ./exe/path_helper --pc
    ./exe/path_helper -p --debug
    exit


## Licence

See the LICENCE file.

