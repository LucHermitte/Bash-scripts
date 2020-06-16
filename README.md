Bash-scripts
============

Miscellaneous scripts to enhance bash (prompt, adding directories to variables, ...)

Table of Contents
* [Scripts](#scripts)
  * [push.bashrc](#pushbashrc)
  * [ssh.bashrc](#sshbashrc)
  * [munge.bashrc](#mungebashrc)
  * [cyg-wrapper.sh](#cyg-wrappersh)
* [Installation](#installation)

## Scripts

### push.bashrc

This script provides a few helpers on top of pushd/popd/dirs functions.
For a description of how these commands are used, see for instance
<http://www.softpanorama.org/Scripting/Shellorama/pushd_and_popd.shtml>

This script overrides the default presentation of the three commands, and
provides the following aliases:

* `d`/`dirs` now displays one pushed directory per line, preceded by the
  directory index within the stack. (this is close to `\dirs -v`).
  When given an argument, `dirs` will display only the pushed directories that
  match the regex.

* `p`/`pushd` and `popd` will display `dirs` result after each directories
  stack modification.

* `p1` to `p9` are aliases on `pushd +1` to `pushd +9`

* `g`/`go` searches for a pushed directory in the stack that matches all the
  regexes received as parameters. If several directories match, the list of
  matching directories is displayed, and the current directory is left
  unchanged.

Other similar aliases can be found over internet, see for instance:
 <http://blogs.sun.com/nico/entry/ksh_functions_galore>.


Other commands aimed at storing bash configuration (directories pushed and
environment variables) are also provided:

* `save_conf <conf-id>` saves the current directories pushed, `env` contents
  and history in the files `$SHELL_CONF/<conf-id>.dirs`,
  `$SHELL_CONF/<conf-id>.env`, and `$SHELL_CONF/<conf-id>.hist`.

* `load_conf <conf-id>` restores the configuration saved with the previous
  command. Actually the environment is not restored. However, the differences
  between the current and the saved environment are displayed.  
  Bash autocompletion is defined for `load_conf`.

The default value for `$SHELL_CONF` is `$HOME/.config/bash`

### ssh.bashrc

This script is meant to be sourced from the `~/.bashrc`. It will ask for the
pass-phrase, once, and then it will remember it for later.

### munge.bashrc

This script is meant to be sourced from the `~/.bashrc` to help help filling
paths into variables like `$PATH`. The main objective is to avoid duplicates in
the path variables.

For instance, with
```bash
munge PATH "$HOME/bin"
munge MANPATH "$HOME/man"
```
you won't end up with `$HOME/bin` twice, or more, into your `$PATH`.

`munge VARIABLE new-path` will add the new path **before** the other ones.

`munge VARIABLE new-path after` will add the new path **after** the other ones.

The script also defines
* `change_or_munge VARIABLE old-path new-path`  to replace a path
* `remove_path VARIABLE paths-to-remove...`  to remove a list of paths
* `clean_path VARIABLE` to remove duplicates
* `munge_std_variables new-path` to define in one go `$PATH`, `$LD_LIBRARY_PATH`, `$MANPATH`, `$INFOPATH`, `$PKG_CONFIG_PATH` depending in what is found in the new directory

All four commands come with autocompletion for bash.

Also, after a

```bash
munge FOOPATH /some/path
munge FOOPATH /other/path
```

A `FOOPATH` alias will be automatically defined, it'll print `$FOOPATH` value,
with each path on a new line. This means that if you use `munge` on `PATH`,
`LD_LIBRARY_PATH`, or `MANPATH`, etc, eponym aliases will be defined!

### nm_and_grep.sh

This small script encapsulates `nm` and `grep`. Typical uses are:
```bash
# Find all libraries having the searched symbol:
find . \( -name '*.so' -o -name '*.a' \) -exec nm_n_grep.sh {} symbol \; -print

# Find in which library used in an executable defines the searched symbol:
ldd executable | sed 's#.*=>[      ]*##' | xargs -I {}  ~1/nm_n_grep.sh -b {} symbol
```


### cyg-wrapper.sh
#####Running a native win32 application from cygwin/bash

The cygwin *NIX emulation layer completly changes the way the paths are
managed. All the cygwin hierarchy appears under the `/`: new root directory as
on unices. Unfortunately, MsWindows native tools (i.e. not using the cygwin
layer) can't understand paths expressed in the UNIX way.  In order to convert
*NIX (i.e. cygwin)-paths into plain MsWindows-paths, we can use: `cygpath -w`.

But, Cygwin also permits many nice things like symbolic links -- try `man ln`.
Unfortunately, *cygpath* seems (at this time) unable to follow these links and
to return the exact MsWindows-path to the linked-files.

Moreover, I had many headaches with the management of spaces on MsWindows 9x
series when using command line invocation of native win32 tools.

So here is `cyg-wrapper.sh`, a shell script that fixes all these problems. It
permits to launch native win32 applications from command-line (or even from
Mutt) with any kind of pathnames passed as parameters.


#####Usage
To get help on the way to use cyg-wrapper, try `cyg-wrapper.sh --help | less`.

In my `~/.profile`, I usually have the following to run native win32 gvim from
cygwin:

```bash
 ### Vim
 ## Little trick for LaTeX-Suite:
 # If one of the parameters is a (La)TeX file, then we declare the
 # servername to be �LATEX�.
 gvim() {
    opt=''
    if [ `expr "$*" : '.*tex\>'` -gt 0 ] ; then
        opt='--servername LATEX '
    fi
    cyg-wrapper.sh "C:/Progra~1/Edition/vim/vim74/gvim.exe" --binary-opt=-c,--cmd,-T,-t,--servername,--remote-send,--remote-expr --cyg-verbose --fork=2 $opt "$@"
 }
 ### Some other windows programs
 alias explore='cyg-wrapper.sh "explorer" --slashed-opt'
 alias mplayer='cyg-wrapper.sh "c:/Progra~1/Window~1/mplayer2.exe"'
```

As a consequence, we can type this.

```bash
    gvim /etc/profile -c /PS1 -c "echo 'correctly opened'"
 # or even:
    cd ~/tmp ; ln -s ~/bin/cyg-wrapper.sh
    gvim -d http://hermitte.free.fr/cygwin/cyg-wrapper.sh cyg-wrapper.sh

    explorer -e
    explorer "$vim"
    explorer http://hermitte.free.fr/
```

#####Requirements
* *cyg*Utils to run and more precisely `realpath`.

## Installation

In order to install all these scripts into `$HOME/bin`, just run
```bash
./install.sh
```

Or, if you'd rather install them elsewhere like `/share/stuff/bin`, type
```bash
./install.sh /share/stuff
```

