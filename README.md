# path_helper

Hard-coding strings is bad, yet you probably hard-code your `PATH`. This way is far more organised. You could even target it with your app! 

Interested? Then read on!

- [What is it?](#what-is-it-)
- [What does that do?](#what-does-that-do-)
- [How do i get this wonderful joyful event maker into my life? A.K.A. install instructions](#how-do-i-get-this-wonderful-joyful-event-maker-into-my-life-)
- [How does the Apple one work?](#how-does-the-apple-one-work-)
- [Why replace it?](#why-replace-it-)
- [More drawbacks to Apple's way](#more-drawbacks-to-apple-s-way)
- [Do i need to be on Apple to use it? (Short answer, no)](#do-i-need-to-be-on-apple-to-use-it-)
- [How does path_helper know what to put in the path?](#how-does-path-helper-know-what-to-put-in-the-path-)
- [Per user paths](#per-user-paths)
- [Pre-req](#pre-req)
- [Way 1: Use the paths, Luke](#way-1--use-the-paths--luke)
- [Way 2: paths.d/](#way-2--paths-d-)
- [Why use the paths.d sub directory?](#why-use-the-paths-d-sub-directory)
- [Ordering](#ordering)
- [Why Library/Paths/paths and not Library/paths?](#why-library-paths-paths-and-not-library-paths-)
- [MAN and DYLD and C_INCLUDE and PKG_CONFIG](#man-and-dyld-and-c-include-and-pkg-config)
- [MANPATH](#manpath)
- [DYLD_FALLBACK_LIBRARY_PATH and DYLD_FALLBACK_FRAMEWORK_PATH](#dyld-fallback-library-path-and-dyld-fallback-framework-path)
- [C_INCLUDE_PATH](#c-include-path)
- [PKG_CONFIG_PATH](#pkg-config-path)
- [An example install](#an-example-install)
- [The ability to debug your paths](#the-ability-to-debug-your-paths)
- [Development](#development)
- [To get set up for development](#to-get-set-up-for-development)
- [To run the specs](#to-run-the-specs)
- [Shell in and have a play](#shell-in-and-have-a-play)
- [Licence](#licence)

## <a name="what-is-it-">What is it?</a>

A replacement for Apple's `/usr/libexec/path_helper`.

## <a name="what-does-that-do-">What does that do?</a>

Apple's path_helper helps set the `PATH` and `MANPATH` environment variables, which is good but there are some significant problems with the way they've done it. This one fixes the bad stuff and builds on the good stuff. The 3 most important features are:

1. It has per user paths as well as system wide ones.
2. It extends the concept to include other paths than just `PATH` and `MANPATH`.
3. It's got some helpful output for debugging your paths.

and one more for luck

4. It's got no side effects, you simply ask it for a path and it gives back a path, no eval or setting the `PATH` inside the script.

### How do i get this wonderful joyful event maker into my life? A.K.A. install instructions

It's just a script with no dependencies other than Ruby.

- Download it (e.g. `git clone` or a download link, you can even just copy and past the [script](https://raw.githubusercontent.com/yb66/path_helper/master/exe/path_helper))
- Make sure it has the correct permissions (`chmod +x`)
- Have a look at the help by running it with `-h`.
- Run the `--setup` (take note of the `--lib` and `--config` and their `--no-` counterparts)
- Copy and paste the bit setup tells you to, and put it in your `~/.zshenv` or `~/.bashenv`
- Find your life is so much better now it's easy to manage your paths

*It doesn't need to be in* `/usr/local/bin`, or any special place, just `chmod +x` it and call it by the full path and it'll plop out a string for you.

See [An example install](#an-example-install) for more.

## <a name="how-does-the-apple-one-work-">How does the Apple one work?</a>

Segments of the path are defined in text files under `/etc/paths.d` and in `/etc/path`. For example, on my machine:

```shell
$ tree /etc/paths.d
/etc/paths.d
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

$ cat /etc/paths /etc/paths.d/*
/usr/local/bin
/usr/local/sbin
/usr/bin
/usr/sbin
/bin
/sbin
/Applications/GPAC.app/Contents/MacOS/
/Applications/BitKeeper.app/Contents/Resources/bitkeeper
/opt/pkg/sbin
/opt/pkg/bin
/opt/local/bin
/Library/Developer/CommandLineTools/usr/bin
/usr/local/MacGPG2/bin
/usr/local/share/dotnet
~/.dotnet/tools
/usr/local/go/bin
/Library/Frameworks/Mono.framework/Versions/Current/Commands
/Applications/Xamarin Workbooks.app/Contents/SharedSupport/path-bin
/usr/local/sbin
/usr/bin
/usr/sbin
/bin
/sbin
/Applications/GPAC.app/Contents/MacOS/
```

## <a name="why-replace-it-">Why replace it?</a>

Because Apple's one loads the system libraries to the front, take a look:

```shell
$ /usr/libexec/path_helper
PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/Applications/GPAC.app/Contents/MacOS/:/usr/local/go/bin:/Library/Developer/CommandLineTools/usr/bin:<snip!>
```
  
…the rest of the items are added *after*, which means anything you add to `/etc/paths.d/` will end up after the system libraries.
  
Want your up-to-date OpenSSL installed via [Macports](https://trac.macports.org/) to be first in the PATH? 
Apple says *"too bad!"*
  
Want your much newer version of LLVM installed via [pkgsrc](https://pkgsrc.joyent.com/) to be hit first?
Apple says *"too bad!"*

Well, there are alternatives.

## <a name="more-drawbacks-to-apple-s-way">More drawbacks to Apple's way</a>

Where the Apple `path_helper` falls down is:

- It puts things in `/etc`, meaning you need elevated permissions to add/remove path segments.
- Being in `/etc` also makes them system wide.
- It's only for `PATH` and `MANPATH` but development and administration often need headers and libraries accessible in the same way too.
- The string it returns is designed to be `eval`'d. I know that `eval` isn't *always* evil but why not just return the `PATH` string and allow it to be set to a variable? Maybe there's more to be added.

## <a name="do-i-need-to-be-on-apple-to-use-it-">Do i need to be on Apple to use it?</a>

No, it should work on any unix-like system. It has one dependency, and that is Ruby. It should work with any system running Ruby 2.3.7 or above, as that is the version that ships with a Mac.

## <a name="how-does-path-helper-know-what-to-put-in-the-path-">How does path_helper know what to put in the path?</a>

Apple has put paths in `/etc/paths` and further files are there for the user or apps to add under `/etc/paths.d/`. If you want to order them then prefixing a number works well, e.g.

```shell
$ tree /etc/paths.d
/etc/paths.d
├── 10-pkgsrc
└── MacGPG2
└── ImageMagick
```

The format of the file is simply a path per line, e.g.

```shell
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
```

The order *within* the file matters as well as the order the files are read/concatenated.

### Note: ###

The `/etc/paths` file in Apple isn't set out fully or in the order I'd want so I changed mine, you may want to do the same.


## <a name="per-user-paths">Per user paths</a>

This is the bit I like best.

Apple's path\_helper doesn't help with paths that may only be applicable for a single user. This version will check the following per user directories for path info:

- `~/Library/Paths/paths.d` and
- `~/Library/Paths/paths`
- `~/.config/paths.d/` and
- `~/.config/paths`

You can use the `--setup` switch to have the path_helper set up the directory layout and files, you just have to fill them!

You can also use the tilde `~` character in a path by replacing it with the `HOME` env variable. For example, if I install Haskell and want to put it in my path I can do the following:

### <a name="pre-req">Pre-req</a>

```shell
path_helper --setup --no-config --no-etc
```

This would set up the `~/Library/Paths` for you, which fits a Mac very well.

```shell
path_helper --setup --no-lib --no-etc
```

You might choose this way if you're on a Mac or using Linux. It's up to you.

### <a name="way-1--use-the-paths--luke">Way 1: Use the paths, Luke</a>

On my Mac, Haskell resides in `~/Library/Haskell`.

```shell
$ echo '~/Library/Haskell/bin' > ~/Library/Paths/paths

$ tree ~/Library/Paths 
/Users/iainb/Library/Paths
├── paths
└── paths.d

$ cat ~/Library/Paths/paths                          
~/Library/Haskell/bin
```

That puts `/Users/iainb/Library/Haskell/bin` at the front of my path and will only apply to my account's `PATH`.

### <a name="way-2--paths-d-">Way 2: paths.d/</a>

```shell
$ touch ~/Library/Paths/paths.d/60-Haskell

$ tree ~/Library/Paths 
/Users/iainb/Library/Paths
├── paths
└── paths.d
    └── 60-Haskell
```

## <a name="why-use-the-paths-d-sub-directory">Why use the paths.d sub directory?</a>

Perhaps if I show you my actual set up it'll become clearer:

```shell
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
```

Imagine uninstalling Haskell and wanting to remove it from the PATH - are you sure you removed all of it? All the right parts? Did you make a typo?

Imagine you've developed a tool but on install you have to get the user to manually edit their PATH, or perhaps you're going to rely on `PATH="/my/obnoxious/munging:$PATH"`?

Once you start installing various things it makes sense to keep their paths in their own file, it's easier to organise (and remove). It's also easy for apps to target this to easily add things to a path. Some apps already do this by adding to `/etc/paths.d` (although that obviously needs elevated privileges and makes things system wide, so again, per user paths are better).

## <a name="ordering">Ordering</a>

path_helper will read files in this order:

1. `~/Library/Paths/paths.d`
2. `~/Library/Paths/paths`
3. `~/.config/paths.d`
4. `~/.config/paths`
5. `/etc/paths.d`
6. `/etc/paths`

If you don't have any of those dirs/files, they are skipped. Files within the `.d` dirs are read in file system order.

## <a name="why-library-paths-paths-and-not-library-paths-">Why Library/Paths/paths and not Library/paths?</a>

Because this is such a useful pattern that it can be extended for headers and includes, so `~/Library/Paths/paths` is for the PATH, `~/Library/Paths/manpaths` is for the MANPATH etc.

## <a name="man-and-dyld-and-c-include-and-pkg-config">MAN and DYLD and C_INCLUDE and PKG_CONFIG</a>

### <a name="manpath">MANPATH</a>

Apple has already dictated that `/etc/manpaths` and `/etc/manpaths.d/` are the default paths for setting `MANPATH`, so the same pattern has been followed for that as with `PATH`:

- `~/Library/Paths/manpaths.d/`
- `~/Library/Paths/manpaths`
- `~/.config/manpaths.d/`
- `~/.config/manpaths`
- `/etc/manpaths.d/`
- `/etc/manpaths`

I can tell you it's a very pleasant experience typing `man blah` for the thing I just installed and getting the correct man page up.


### <a name="dyld-fallback-library-path-and-dyld-fallback-framework-path">DYLD_FALLBACK_LIBRARY_PATH and DYLD_FALLBACK_FRAMEWORK_PATH</a>

Same goes for DYLD_FALLBACK_LIBRARY_PATH and DYLD_FALLBACK_FRAMEWORK_PATH:

- `~/Library/Paths/dyld_library_paths.d/`
- `~/Library/Paths/dyld_library_paths`
- `~/.config/dyld_library_paths.d/`
- `~/.config/dyld_library_paths`
- `/etc/dyld_library_paths.d/`
- `/etc/dyld_library_paths`

and:

- `~/Library/Paths/dyld_framework_paths.d/`
- `~/Library/Paths/dyld_framework_paths`
- `~/.config/dyld_framework_paths.d/` 
- `~/.config/dyld_framework_paths` 
- `/etc/dyld_framework_paths.d/`
- `/etc/dyld_framework_paths`


### <a name="c-include-path">C_INCLUDE_PATH</a>

Same again for `C_INCLUDE_PATH`:

- `~/Library/Paths/include_paths.d/`
- `~/Library/Paths/include_paths`
- `~/.config/include_paths.d/`
- `~/.config/include_paths`
- `/etc/include_paths.d/`
- `/etc/include_paths`

### <a name="pkg-config-path">PKG_CONFIG_PATH</a>

Did you know that there's a `PKG_CONFIG_PATH`? There is, check the man page, it's very helpful.

- `~/Library/Paths/pkg_config_paths.d/`
- `~/Library/Paths/pkg_config_paths`
- `~/.config/pkg_config_paths.d/`
- `~/.config/pkg_config_paths`
- `/etc/pkg_config_paths.d/`
- `/etc/pkg_config_paths`


## <a name="how-do-i-get-this-wonderful-joyful-event-maker-into-my-life-">How do i get this wonderful joyful event maker into my life?</a>


## <a name="an-example-install">An example install:</a>

You could put the path_helper in `/usr/local/libexec` and mirror the Apple set up, so that other accounts to be able to access its goodness, but you can put it anywhere you like.

```shell
sudo mkdir -p /usr/local/libexec
```

Currently I run one from `~/bin` so I don't bother with that.

```shell
mkdir ~/bin
```

Download the file then make sure it has the correct permissions:

```shell
chmod +x ~/bin/path_helper
```

Look at the help because you're not like everyone else, you read instructions ;-)

```shell
~/bin/path_helper --help
```

You need `sudo` to add the folders in `/etc`, see the `--help` if you don't want that. I don't want that, and let's say I prefer using `~/.config` to `~/Library` because I'm on a Linux system:

```shell
~/bin/path_helper --setup --no-etc --no-lib
```

See what's already there and why:

```shell
~/bin/path_helper --path --debug
```

**Note**: Apple's path_helper is in `/usr/libexec`, this install won't touch it, you can always use it or return to it if you wish.

And checking its output (debug shows you that too):

```shell
$ ~/bin/path_helper --path
    /opt/pkg/sbin:/opt/pkg/bin:/opt/X11/bin:/opt/ImageMagick/bin:/usr/local/MacGPG2/bin:/usr/local/git/bin:/opt/puppetlabs/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"
```

To put it into the PATH via the command line:

```shell
$ PATH=$(~/bin/path_helper -p)
$ export PATH
```

but you'll probably use the helpful instructions `--setup` provides at the end of setting up:

```shell
# Put this in your ~/.bashrc or your ~/.zshenv
if [ -x /Users/$USER/Projects/path_helper/exe/path_helper ]; then
  C_INCLUDE_PATH=$(ruby /Users/$USER/Projects/path_helper/exe/path_helper -c)
  DYLD_FALLBACK_FRAMEWORK_PATH=$(ruby /Users/$USER/Projects/path_helper/exe/path_helper --dyld-fram)
  DYLD_FALLBACK_LIBRARY_PATH=$(ruby /Users/$USER/Projects/path_helper/exe/path_helper --dyld-lib)
  MANPATH=$(ruby /Users/$USER/Projects/path_helper/exe/path_helper -m)
  PKG_CONFIG_PATH=$(ruby /Users/$USER/Projects/path_helper/exe/path_helper -pc)
  PATH=$(ruby /Users/$USER/Projects/path_helper/exe/path_helper -p)
fi

export C_INCLUDE_PATH
export DYLD_FALLBACK_FRAMEWORK_PATH
export DYLD_FALLBACK_LIBRARY_PATH
export MANPATH
export PKG_CONFIG_PATH
export PATH
```

### NOTE!

Remember, it **won't set the PATH**, it *returns* a path, **you have to set the path** with it e.g. `PATH=$(/usr/local/libexec/path_helper.rb -p)`. Call `/usr/local/libexec/path_helper -h` to see all the options.

### Another NOTE!

The because the Ruby team decided to spam us with warnings about everything so quite often recently I get a lot of unhelpful stuff filling up my terminal on open. Thanks, Ruby core team!

To quieten it down change:

```shell
PATH=$(ruby /path/to/path_helper -p)
```

to:

```shell
PATH=$(ruby /path/to/path_helper -p 2>/dev/null)
```

## <a name="the-ability-to-debug-your-paths">The ability to debug your paths</a>

The `--debug` flag is *really* helpful. For example:

```shell
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
```

Everything you need to know! Very useful for working out when other things are manipulating the path too.

## <a name="development">Development</a>

I'm happy to hear from you, email me or open an issue. Pull requests are fine too, try to bring me a spec or an example if you want a feature or find a bug.

### To get set up for development

Run:

```shell
packer build docker/docker.pkr.hcl
```


### <a name="to-run-the-specs">To run the specs</a>

```shell
docker run --rm yb66/path_helper:4.0.0-ph-r237
docker run --rm yb66/path_helper:4.0.0-ph-r270
```

### <a name="shell-in-and-have-a-play">Shell in and have a play</a>

```shell
docker run --rm -ti --entrypoint="" yb66/path_helper sh
```

Run some tests yourself:

```shell
./spec/shell_spec.sh
```

Set up some paths using the test fixtures:

```shell
./exe/path_helper --setup --no-lib
cp -R spec/fixtures/moredirs/* ~/.config/paths
```

Have a look at the output by running through the available paths:

```shell
./exe/path_helper -p
./exe/path_helper -c
./exe/path_helper -f
./exe/path_helper -l
./exe/path_helper -m
./exe/path_helper --pc
./exe/path_helper -p --debug
```

Add colour support to the terminal so you can see the prettiness:

```shell
apk add ncurses
./exe/path_helper -p --debug
```

You may want to have the env vars set. Run:

```shell
source ~/.ashenv
echo $PATH
echo $C_INCLUDE_PATH
# etc
```

Modify some of the path files

```shell
apk add vim
vim ~/.config/paths/paths.d/03-libiconv
vim ~/.config/paths/paths.d/01-Nim
./exe/path_helper -p
# ...
exit
```

## <a name="#licence">Licence</a>

See the LICENCE file.

