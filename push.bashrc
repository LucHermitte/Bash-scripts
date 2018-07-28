# Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
# Purpose:      Aliases for mananing directories stack.
# Licence:      GPL2
# Version:      1.6.0
#
# Installation:
#       Source this file from your .bahrc/.profile
#       Requires a shell that implements directories stack like bash,
#       and the following programs: perl, cut, grep, and cat.
# ----------------------------------------------------------------------
# Usage:
#   This script provides a few helpers on top of pushd/popd/dirs
#   functions.
#   For a description of how these commands are used, see for instance
#   <http://www.softpanorama.org/Scripting/Shellorama/pushd_and_popd.shtml>
#
#   This script overrides the default presentation of the three
#   commands, and provides the following aliases:
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
#   - g/go searches for a pushed directory in the stack that matches all
#     the regexes received as parameters. If several directories match,
#     the list of matching directories is displayed, and the current
#     directory is left unchanged.
#
#   - `save_conf <conf-id>` saves the current directories pushed, `env`
#     contents and history in the files `$SHELL_CONF/<conf-id>.dirs`,
#     `$SHELL_CONF/<conf-id>.env`, and `$SHELL_CONF/<conf-id>.hist`.
#
#   - `load_conf <conf-id>` restores the configuration saved with the
#     previous command. Actually the environment is not restored.
#     However, the differences between the current and the saved
#     environment are displayed.
#     Bash autocompletion is defined for `load_conf`.
#
#  The default value for `$SHELL_CONF` is `$HOME/.config/bash`
#
# ----------------------------------------------------------------------
# Other similar aliases can be found over internet, see for instance:
# <http://blogs.sun.com/nico/entry/ksh_functions_galore>.
#
# ----------------------------------------------------------------------
### Helper functions {{{1
# _is_unset {{{2
function _is_unset()
{
    [[ -z ${!1+x} ]]
}

# _is_set {{{2
function _is_set()
{
    # [[ -v $1 ]] with bash 4.2+
    [[ -n ${!1+x} ]]
}

# _die {{{2
function _die()
{
   local msg=$1
   [ -z "${msg}" ] && msg="Died"
   printf "%s" "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: ${FUNCNAME[1]}: ${msg}" >&2
   # printf "%s\n" "${msg}" >&2
   return 0
}

# _save_file {{{2
function _save_file()
{
    local file=$1
    if [ -f "${file}" ] ; then
        mv "${file}" "${file}.old"
        echo "Previous bash configuration ${file}.env moved to ${file}.old."
    fi
}

# ----------------------------------------------------------------------
### Directory pushing {{{1
## Display the directories pushed {{{2

if [ 0 == 1 ] ; then
    # Si gawk
    d() { command dirs | gawk  '{gsub(/ ~/, "!~"); gsub(/ \//, "!/") ; n=split($0,arr,"!") ; for (i=1;i<=n;++i) print (i-1)" -> "arr[i] }'
    }
else
    maybegrep() {
        if [ $# -gt 0 ] ; then
            grep "$1"
        else
            cat
        fi
}
    # Si pas gawk
    # d() { command dirs | sed 's# \([/.~]\)#\1#g' |grep -n . | sed 's#:#-> #'
    # d() { command dirs | perl -pe "s# ([/.~])#\n\1#g" |grep -n . | sed 's#:# -> #'
    #}
    #d() { command dirs | perl -e '@t=<> ; @s = map ( { split(" ",$_) } @t) ; for ($n=0 ; $s[$n] ; ++$n) { print "$n --> " ; print "\033[00;34;34m" if ($n==0) ; print "$s[$n]\n" ; print "\033[01;00;0m" if ($n==0)}'
    #}
    d() { command dirs | perl -e '@t=<> ; @s = map ( { split(" (?=[/~])",$_) } @t) ; for ($n=0 ; $s[$n] ; ++$n) { print "$n --> " ; print "\033[33m" if ($n==0) ; print "$s[$n]" ; print "\033[01;00;0m" if ($n==0) ; print "\n"}' | maybegrep "$@"
}
fi
alias dirs=d
# Note: We can not directly write «dirs() { command dirs | ... }» as it would
# end in an infinite loop. Hence the declaration of «d(){}» and dirs as
# an alias for d.

# ----------------------------------------------------------------------
## Push a directory {{{2
p() {
    if [ -z "$*" ] ; then
        # If no parameter, we do not want to push the current directory
        command pushd > /dev/null
    else
        # The quotes in «"$*» permit to write «p $vim»
        command pushd "$*" > /dev/null
    fi
    # List the directories pushed
    d
}

# ----------------------------------------------------------------------
## Move to a pushed directory {{{2
alias   p1="p +1"
alias   p2="p +2"
alias   p3="p +3"
alias   p4="p +4"
alias   p5="p +5"
alias   p6="p +6"
alias   p7="p +7"
alias   p8="p +8"
alias   p9="p +9"

# ----------------------------------------------------------------------
## Pop a directory {{{2
# Same workaround than «d()» and «dirs»
function popd_int()
{
    command popd "$@" > /dev/null
    d
}
alias popd=popd_int

# ----------------------------------------------------------------------
## grep all: do multiple grep to match all args {{{2
grep_all() {
    res="grep $1"
    declare -a args=("$@")
    for arg in "${args[@]:1}" ; do
        res="${res} | grep ${arg}"
    done
    eval $res
}
# ----------------------------------------------------------------------
## Go to a directory mathing a given pattern {{{2
# <=> d <pattern> && p +<correct-offset>
g() {
    if [ $# -eq 0 ] ; then
        echo "USAGE: g <pattern>"
        echo "Incorrect number of arguments"
        echo ""
        echo "This command searches for a pushed directory having the <pattern>"
        echo "in its name and goes to it."
        echo ""
        echo "See pushd (aliased to p), dirs (aliased to d), and popd"
    else
        local all_dirs
        local matching_dirs
        all_dirs=$(dirs)
        matching_dirs=$(printf "%s" "$all_dirs"| grep_all "$@")
        if [ $? -eq 1 ] ; then
            echo "g: there is no pushed directories matching '$*'"
            printf "%s" "$all_dirs"
        else
            local nb
            nb=$(echo "$matching_dirs" | wc -l)
            #echo $(echo "$matching_dirs" | wc )
            if [ $nb -gt 1 ] ; then
                echo "g: there are too many pushed directories matching '$*'"
                printf "%s" "$matching_dirs"
            else
                local which
                which=$(echo "$matching_dirs" |cut -f 1 -d " ")
                p +"$which"
            fi
        fi
    fi
}
alias go=g

# ----------------------------------------------------------------------
### Environment {{{1

## Save configuration {{{2
save_conf() {
    [[ $# -ge 1 ]] && bash_conf=$1
    [[ -z ${bash_conf} ]] && _die "save_conf <id-conf>" && return 1
    local shell_conf_files="${SHELL_CONF:-${HOME}/.config/bash}"
    if [ ! -d "${shell_conf_files}" ] ; then
        mkdir "${shell_conf_files}" || (echo "Cannot create configuration directory" && return 2)
    fi
    local conf_file=${shell_conf_files}/${bash_conf}

    _save_file "${conf_file}.env"
    _save_file "${conf_file}.dirs"
    _save_file "${conf_file}.hist"

    export HISTFILE="${conf_file}.hist"
    command dirs -p > "${conf_file}.dirs"
    echo "${bash_conf}" > "${conf_file}.env"
    env | grep -E -v "proxy" >> "${conf_file}.env"
    history -w
    echo "Bash configuration ${bash_conf} saved (in ${shell_conf_files})."
}

## Which terminal emulator {{{2
# http://unix.stackexchange.com/questions/170428/identify-whether-terminal-is-open-in-guake
# Note however that on Cygwin, ps doesn't support -o
which_terminal_emulator() {
    set -f
    pid=$PPID
    case $(uname -o) in
        Cygwin)
            my_tty=$(cat /proc/$$/ctty)
            while [ "$pid" -ne 1 ] && set -- $(cat /proc/$pid/ppid /proc/$pid/exename) && [ "$(cat /proc/$pid/ctty)" = "$my_tty" ]
            do
                pid=$1
            done
            shift
            ;;
        *)
            my_tty=$(ps -p $$ -o tty=)
            while [ "$pid" -ne 1 ] && set -- $(ps -p "$pid" -o ppid= -o tty= -o args=) && [ "$2" = "$my_tty" ]
            do
                pid=$1
            done
            shift; shift
            ;;
    esac
    printf '%s\n' "$*"
}

## Restore configuration {{{2
load_conf() {
    if [ $# -lt 1 ] ; then
        echo "load_conf <id-conf>"
        return 1
    fi
    bash_conf=$1
    local shell_conf_files=${SHELL_CONF:-${HOME}/.config/bash}
    local conf_file=${shell_conf_files}/${bash_conf}
    if [ ! -f  "${conf_file}.dirs" ] ; then
        echo "There no conf ${bash_conf} in ${shell_conf_files}. Aborting."
        return 2
    fi
    # TODO: test with directories with spaces
    command dirs -c
    local n=0
    # for i in $(cat "${conf_file}.dirs")
    while IFS= read -r i
    do
        if [ $n -eq 0 ] ; then
            command cd "${i/\~/$HOME}" > /dev/null
            ((n++))
        else
            command pushd "${i/\~/$HOME}" > /dev/null
        fi
    done < <(tac "${conf_file}.dirs")
    # TODO: check tac is present
    # tac == cat, but reverse lines
    dirs

    export HISTFILE="${conf_file}.hist"
    if [ -f "${conf_file}.env" ] ; then
        local tmpfile
        tmpfile="$(mktemp)"
        env | grep -E -v "proxy" >> "${tmpfile}"
        echo "Here follows environment differences between loaded configuration (+) and current configuration (-)"
        diff -U 0 "${tmpfile}" "${conf_file}.env" | grep -E -v "@@|^---|^\+\+\+|PID|SESSION|SSH|AUTH|DISPLAY|PWD"
        rm "${tmpfile}"
    fi

    local term
    term="$(which_terminal_emulator)"
    [ "${term/guake/}" != "$term" ] && guake -r "${bash_conf}"
    [ -f "${HISTFILE}" ] && history -r
    echo "..."
    echo "Bash configuration ${bash_conf} loaded (from ${shell_conf_files})."
}

## auto-save {{{3
function _on_exit_save_conf()
{
    _is_unset bash_conf || save_conf
}
trap '_on_exit_save_conf' EXIT


## Completion {{{2
# _load_conf {{{3
function _load_conf()
{
    local shell_conf_files=${SHELL_CONF:-${HOME}/.config/bash}
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(command ls "${shell_conf_files}"/*.dirs | sed "s#\.dirs##g" | xargs -L1 basename | grep "^${cur}.*"))

    return 0
}
complete -F _load_conf load_conf

# }}}1
# ----------------------------------------------------------------------
# vim:ft=sh:fdm=marker
