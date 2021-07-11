#!/bin/bash

# Script Purpose         {{{1
# This scripts helps to install Bash-Scripts into $HOME/bin.
# Hard links will be created in ~/bin for the main scripts in the
# current directory.
#


# License: CC-BY-SA 3.0 v2 {{{1

# Code                   {{{1

# Obtain current script dir {{{2
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in/2633580#2633580
# This comment and code Copyleft, selectable license under the GPL2.0 or
# later or CC-SA 3.0 (CreativeCommons Share Alike) or later. (c) 2008.
# All rights reserved. No warranty of any kind. You have been warned.
# http://www.gnu.org/licenses/gpl-2.0.txt
# http://creativecommons.org/licenses/by-sa/3.0/
current_dir() {
    pushd $(dirname $(readlink -f "$BASH_SOURCE")) > /dev/null
    local SCRIPT_DIR="$PWD"
    popd > /dev/null
    echo $SCRIPT_DIR
}
# ----

# Usage and options {{{2
usage() {
    echo "USAGE: $0 [-v|--verbose] [-s|--symlink] [HOMEDIR]"
    echo "USAGE: $0 [-h|--help]"
}


verbose=0
symlink=""
HOMEDIR=""

while [ $# -gt 0 ] ; do
    case $1 in 
        -h|--help)
            usage
            exit -1
            ;;
        -v|--verbose)
            verbose=1
            shift
            ;;
		-s|--symlink)
			symlink="-s"
			shift
			;;
        *)
            if [ x"$HOMEDIR0" != x"" ] ; then
                echo "$0: Error HOMEDIR already overridden"
                usage
                exit 1
            fi
            HOMEDIR0=$1
            shift
            ;;
    esac
done
HOMEDIR=${HOMEDIR0:-$HOME}

# The main code

ORIG=$(current_dir)
cd "$ORIG"

files=$(ls *.bashrc *.sh)

if [ ! -d "$HOMEDIR/bin" ]; then
	mkdir "$HOMEDIR/bin"

	if [ $verbose -gt 0 ] ; then
		echo mkdir "$HOMEDIR/bin"
	fi
fi
cd "$HOMEDIR/bin"

if [ $verbose -gt 0 ] ; then
    echo cd "$HOMEDIR/bin"
fi
for f in $files ; do
    case $f in 
        install.sh) # ignore this script
            continue
            ;;
        cyg-wrapper.sh) # ignore cyg-wrapper.sh on non-cygwin systems
            uname=$(uname)
            if [ "${uname/CYGWIN/}" = "$uname" ] ; then
                continue
            fi
            ;;
    esac

    if [ $verbose -gt 0 ] ; then
        echo ln "$ORIG/$f"
    fi

	if [ -L "$f" ]; then
		rm "$f"
	elif [ -e "$f" ]; then
		while true; do
			read -p "$f exists and is not a symbolic link, delete anyway? [Y/N] " yn
			case $yn in
				[Yy]* )
					rm -rf $f
					break;
					;;
				[Nn]* )
					echo "Skipping $f"
					continue 2
					;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	fi

    ln $symlink "$ORIG/$f"
done


# vim:set fdm=marker:

