# path_helper

Simple replacement of Apple's `/usr/libexec/path_helper` using bash script to set the path with the system dirs at the back, e.g. /bin /usr/bin etc are last in the path, because if I've installed anything I want it to come first in the path (or why install it?)

## Install

Copying script to a better location:

    $ sudo make
    install -m 0755 ./path_helper /usr/local/libexec/

Apple's path_helper is in /usr/libexec, so the default here is /usr/local/libexec.

And checking its output:

    $ /usr/local/libexec/path_helper
    PATH="/opt/pkg/sbin:/opt/pkg/bin:/opt/X11/bin:/opt/ImageMagick/bin:/usr/local/MacGPG2/bin:/usr/local/git/bin:/opt/puppetlabs/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"; export PATH;

### ZSH

We also need to inform `ZSH` about the new `path_helper`:

    if [ -x /usr/local/libexec/path_helper ]; then
      eval `/usr/local/libexec/path_helper`
    fi

The makefile will print out what needs to go in, if you change any of the settings.

## Source Files

The script will expect to have the following source files name convention, for example:

    $ ls -1 /etc/paths.d
    00-local
    10-base_system
    git
    ImageMagick
    50-otaviof
