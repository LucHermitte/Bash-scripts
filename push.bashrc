# $Id$ 
# Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
# Purpose:	Aliases for mananing directories stack.
# Licence:	GPL2
# Version:	1.0
#
# Installation:
# 	Source this file from your .bahrc/.profile
# 	Requires a shell that implements directories stack like bash, 
# 	and the following programs: perl, cut, grep, and cat.
# ----------------------------------------------------------------------
# Usage:
#   This script provides a few helpers on top of pushd/popd/dirs
#   functions.
#   For a description of how these commands are used, see for instance
#   <http://www.softpanorama.org/Scripting/Shellorama/pushd_and_popd.shtml>
#
#   This script overrides the default presentation of the three
#   commands, and provides a aliases:
#
#   - d/dirs now displays one pushed directory per line, preceded by the
#     directory index wihthin the stack. (this is close to \dirs -v)
#     When given an argument, dirs will display only the pushed
#     directories that match the regex.
#
#   - p/pushd and popd will display dirs result after each directories
#     stack modification.
#
#   - p1 to p9 are aliases on "pushd +1" to "pushd +9"
#
#   - g/go searches for a pushed directory in the stack that matches the
#     regex received as parameter. If several directories match, the
#     list of matching directories is displayed, and the current
#     directory is left unchanged.
# ----------------------------------------------------------------------
# Other similar aliases can be found over internet, see for instance:
# <http://blogs.sun.com/nico/entry/ksh_functions_galore>.
#
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
### Directory pushing
## Display the directories pushed

if [ 0 == 1 ] ; then
    # Si gawk
    d() { \dirs | gawk  '{gsub(/ ~/, "!~"); gsub(/ \//, "!/") ; n=split($0,arr,"!") ; for (i=1;i<=n;++i) print (i-1)" -> "arr[i] }'
    }
else
    maybegrep() {
	if [ $# -gt 0 ] ; then
	    grep $1
	else
	    cat
	fi
}
    # Si pas gawk
    # d() { \dirs | sed 's# \([/.~]\)#\1#g' |grep -n . | sed 's#:#-> #'
    # d() { \dirs | perl -pe "s# ([/.~])#\n\1#g" |grep -n . | sed 's#:# -> #'
    #}
    #d() { \dirs | perl -e '@t=<> ; @s = map ( { split(" ",$_) } @t) ; for ($n=0 ; $s[$n] ; ++$n) { print "$n --> " ; print "\033[00;34;34m" if ($n==0) ; print "$s[$n]\n" ; print "\033[01;00;0m" if ($n==0)}'
    #}
    d() { \dirs | perl -e '@t=<> ; @s = map ( { split(" (?=[/~])",$_) } @t) ; for ($n=0 ; $s[$n] ; ++$n) { print "$n --> " ; print "\033[33m" if ($n==0) ; print "$s[$n]" ; print "\033[01;00;0m" if ($n==0) ; print "\n"}' | maybegrep "$@"
}
fi
alias dirs=d
# Note: We can not directly write «dirs() { \dirs | ... }» as it would
# end in an infinite loop. Hence the declaration of «d(){}» and dirs as
# an alias for d.

# ----------------------------------------------------------------------
## Push a directory
p() { 
    if [ -z "$*" ] ; then 
	# If no parameter, we do not want to push the current directory
	\pushd > /dev/null
    else
	# The quotes in «"$*» permit to write «p $vim»
	\pushd "$*" > /dev/null
    fi
    # List the directories pushed
    d
}

# ----------------------------------------------------------------------
## Move to a pushed directory
alias	p1="p +1"
alias	p2="p +2"
alias	p3="p +3"
alias	p4="p +4"
alias	p5="p +5"
alias	p6="p +6"
alias	p7="p +7"
alias	p8="p +8"
alias	p9="p +9"

# ----------------------------------------------------------------------
## Pop a directory
# Same workaround than «d()» and «dirs»
popd_int() { \popd $* > /dev/null ; d
}
alias popd=popd_int

# ----------------------------------------------------------------------
## Go to a directory mathing a given pattern
# <=> d <pattern> && p +<correct-offset>
g() {
    if [ $# -eq 0 ] ; then
	p
    elif [ $# -eq 1 ] ; then
	all_dirs=$(dirs)
	matching_dirs=$(printf "$all_dirs"| grep "$@")
	if [ $? -eq 1 ] ; then
	    echo "g: there is no pushed directories matching '$@'"
	    printf "$all_dirs"
	else
	    nb=$(echo "$matching_dirs" | wc -l)
	    #echo $(echo "$matching_dirs" | wc )
	    if [ $nb -gt 1 ] ; then
		echo "g: there are too many pushed directories matching '$@'"
		printf "$matching_dirs"
	    else
		which=$(echo $matching_dirs |cut -f 1 -d " ")
		p +$which
	    fi
	fi
    else
	echo "USAGE: g <pattern>"
	echo "Incorrect number of arguments"
	echo ""
	echo "This command searches for a pushed directory having the <pattern>"
	echo "in its name and goes to it."
	echo ""
	echo "See pushd (aliased to p), dirs (aliased to d), and popd"
    fi
}
alias go=g

# ----------------------------------------------------------------------
# vim:ft=zsh:
