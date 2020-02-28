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

## Man paths and DYLD and C_INCLUDE ##

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

## HOW DO I GET THIS WONDERFUL JOYFUL EVENT MAKER INTO MY LIFE? ##

I was going to make this into a Ruby gem but that is such a faff. Here's the gist of it:

- Download it (use `git clone` or a download link, you can even just copy and past the [script](exe/path_helper))
- Make sure it has the correct permissions (`chmod +x`)
- Run the `--setup`
- Copy and paste the bit setup tells you to, and put it in your `~/.zshenv` or `~/.bashenv`
- Find your life is so much better now it's easy to manage your paths

For example:

# I put my path_helper in `/usr/local/libexec` because I'm the only person using this machine
# and I want my other accounts to be able to access its goodness.
sudo mkdir -p /usr/local/libexec
cd /usr/local/libexec
# ~/Projects/path_helper is where I keep the project
ln ~/Projects/path_helper/exe/path_helper .
chmod +x path_helper
# Look at the help because you're not like everyone else, you read instructions ;-)
path_helper --help
# You need sudo to add the folders in /etc, see the --help if you don't want that
sudo path_helper --setup
# See what's already there
path_helper --debug


Apple's path_helper is in `/usr/libexec`, this install won't touch it, you can always use it or return to it if you wish.

And checking its output:

    $ path_helper
    PATH="/opt/pkg/sbin:/opt/pkg/bin:/opt/X11/bin:/opt/ImageMagick/bin:/usr/local/MacGPG2/bin:/usr/local/git/bin:/opt/puppetlabs/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"; export PATH;

## NOTE!

The script **doesn't set the PATH**, it *returns* a path, **you have to set the path** with it e.g. `PATH=$(/usr/local/libexec/path_helper.rb -p "")`. Call `/usr/local/libexec/path_helper -h` to see all the options.


## My actual system

    $ tree ~/Library/Paths 
    /Users/iainb/Library/Paths
    ├── include_paths
    ├── manpaths.d
    │   └── 30-oh-my-zshell
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

    $ tree /etc/paths.d/
    /etc/paths.d/
    ├── 10-pkgsrc
    ├── 15-macports
    ├── 20-XCode
    ├── MacGPG2
    ├── go
    └── mono-commands


## You know what else is helpful?

The --debug flag. For example:

    $ exe/path_helper --debug           


                                                                      Path | Found in                                 | Ignored duplicate                                           
                                                                      ---- | --------                                 | -----------------                                           
                                                              /opt/pkg/bin | ~/Library/Paths/paths.d/05-pkgsrc        | 
                                                                           | /etc/paths.d/10-pkgsrc                   |   ✗                   
                                                             /opt/pkg/sbin | ~/Library/Paths/paths.d/05-pkgsrc        | 
                                                                           | /etc/paths.d/10-pkgsrc                   |   ✗                   
                                                          /opt/pkg/gnu/bin | ~/Library/Paths/paths.d/05-pkgsrc        | 
                                                            ~/homebrew/bin | ~/Library/Paths/paths.d/08-homebrew      | 
                                                              $HOME/gopath | ~/Library/Paths/paths.d/10-keybase       | 
                                                          $HOME/gopath/bin | ~/Library/Paths/paths.d/10-keybase       | 
                                       ~/.oh-my-zsh/custom/plugins/fzf/bin | ~/Library/Paths/paths.d/30-oh-my-zshell  | 
                                                      ~/Applications/ngrok | ~/Library/Paths/paths.d/50-ngrok         | 
                                                          /opt/crystal/bin | ~/Library/Paths/paths.d/55-Crystal-opt   | 
                                                 /opt/crystal/embedded/bin | ~/Library/Paths/paths.d/55-Crystal-opt   | 
               ~/Library/Frameworks/Crystal.framework/Versions/Current/bin | ~/Library/Paths/paths.d/60-Crystal       | 
      ~/Library/Frameworks/Crystal.framework/Versions/Current/embedded/bin | ~/Library/Paths/paths.d/60-Crystal       | 
                              ~/Library/Frameworks/Opam.framework/Programs | ~/Library/Paths/paths.d/61-Opam          | 
                                                     ~/Library/Haskell/bin | ~/Library/Paths/paths.d/62-Haskell       | 
                            ~/Library/Frameworks/Erlang.framework/Programs | ~/Library/Paths/paths.d/63-Erlang        | 
                                                                  ~/go/bin | ~/Library/Paths/paths.d/63-Go            | 
                                                              ~/.pyenv/bin | ~/Library/Paths/paths.d/64-Pyenv         | 
                                                              ~/.cargo/bin | ~/Library/Paths/paths.d/65-Rust          | 
                                                                     ~/bin | ~/Library/Paths/paths.d/66-Antigen       | 
                                                            /opt/local/bin | /etc/paths.d/15-macports                 | 
                               /Library/Developer/CommandLineTools/usr/bin | /etc/paths.d/20-XCode                    | 
                                                                           | /etc/paths.d/20-XCode                    | 
                                                    /usr/local/MacGPG2/bin | /etc/paths.d/MacGPG2                     | 
                                                         /usr/local/go/bin | /etc/paths.d/go                          | 
              /Library/Frameworks/Mono.framework/Versions/Current/Commands | /etc/paths.d/mono-commands               | 
                                                            /usr/local/bin | /etc/paths                               | 
                                                           /usr/local/sbin | /etc/paths                               | 
                                                                  /usr/bin | /etc/paths                               | 
                                                                 /usr/sbin | /etc/paths                               | 
                                                                      /bin | /etc/paths                               | 
                                                                     /sbin | /etc/paths                               | 


    Current:
    /Users/iainb/.gem/ruby/2.6.3/bin:/Users/iainb/Library/Frameworks/Ruby.framework/Versions/2.6.3/lib/ruby/gems/2.6.0/bin:/Users/iainb/Library/Frameworks/Ruby.framework/Versions/2.6.3/bin:/Users/iainb/.opam/4.06.1/bin:/Users/iainb/perl5/bin:/opt/pkg/bin:/opt/pkg/sbin:/opt/pkg/gnu/bin:/Users/iainb/homebrew/bin:$HOME/gopath:$HOME/gopath/bin:/Users/iainb/.oh-my-zsh/custom/plugins/fzf/bin:/Users/iainb/Applications/ngrok:/Users/iainb/Library/Frameworks/Crystal.framework/Versions/Current/bin:/Users/iainb/Library/Frameworks/Crystal.framework/Versions/Current/embedded/bin:/Users/iainb/Library/Frameworks/Opam.framework/Programs:/Users/iainb/Library/Haskell/bin:/Users/iainb/Library/Frameworks/Erlang.framework/Programs:/Users/iainb/go/bin:/Users/iainb/.pyenv/bin:/Users/iainb/.cargo/bin:/Users/iainb/bin:/opt/local/bin:/usr/local/MacGPG2/bin:/usr/local/go/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin


    If you expected items you'd inserted in the path manually to
    show up earlier then either clear the path before running this
    and reinsert or add paths via:
      (~/Library/Paths|~/config)/paths.d
      (~/Library/Paths|~/config)/paths/*)


    /opt/pkg/bin:/opt/pkg/sbin:/opt/pkg/gnu/bin:/Users/iainb/homebrew/bin:$HOME/gopath:$HOME/gopath/bin:/Users/iainb/.oh-my-zsh/custom/plugins/fzf/bin:/Users/iainb/Applications/ngrok:/opt/crystal/bin:/opt/crystal/embedded/bin:/Users/iainb/Library/Frameworks/Crystal.framework/Versions/Current/bin:/Users/iainb/Library/Frameworks/Crystal.framework/Versions/Current/embedded/bin:/Users/iainb/Library/Frameworks/Opam.framework/Programs:/Users/iainb/Library/Haskell/bin:/Users/iainb/Library/Frameworks/Erlang.framework/Programs:/Users/iainb/go/bin:/Users/iainb/.pyenv/bin:/Users/iainb/.cargo/bin:/Users/iainb/bin:/opt/local/bin:/Library/Developer/CommandLineTools/usr/bin:/usr/local/MacGPG2/bin:/usr/local/go/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin%  

Everything you need to know! Very useful for working out when other things are manipulating the path too.

## Development

I'm happy to hear from you, email me or open an issue. Pull requests are fine too, try to bring me a spec or an example if you want a feature or find a bug.

Sorry the current specs aren't in such good shape, I hope to improve that.

## Licence

See the LICENCE file.

