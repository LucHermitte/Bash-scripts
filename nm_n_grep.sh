#!/bin/bash
# Copyright Luc Hermitte 2006-2014, all rigths reserved
# Licence GPL v3

usage() {
    echo "nm_n_grep.sh [--brief|-b] <library-name> <symbol-searched>"
    echo " Typical use:"
    echo "   find . \( -name '*.so' -o -name '*.a' \) -exec nm_n_grep.sh {} symbol \; -print"
    echo "   ldd executable | sed 's#.*=>[      ]*##' | xargs -I {}  ~1/nm_n_grep.sh -b {} symbol"
}

case $1 in
    -h|--help) usage ; exit 0 ;;
esac
if [ $# -lt 2 ] ; then echo "$0: Syntax error" ; usage ; exit 1 ; fi

brief=0
file=''
regex=''

while [ $# -gt 0 ] ; do
    case $1 in
	-b|--brief)
	    brief=1
	    ;;
	*)
	    if [ x"$file" == x"" ] ; then
		file=$1
	    else
		regex=$1
	    fi
	    ;;
    esac
    shift
done

if [ $brief -eq 1 ] ; then
        (nm -C $file | grep $regex > /dev/null) && echo "$regex found in $file"
else
        nm -C $file | grep $regex
fi
