# ===========================================================================
## Paths list concatenations that avoid duplicates
# Script initially found in the /etc of a linux distribution, then
# patched by Luc Hermitte.
# Licence, likely GPL v2. To be confirmed.
#
# Examples:
# $ munge PATH "$HOME/bin"
# $ munge MANPATH "$HOME/man"
unset verbose_munge
# verbose_munge=1

## Helper functions {{{1
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
   # printf "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: ${FUNCNAME[1]}: ${msg}" >&2
   printf "${msg}" >&2
   return 0
}

## Path list manipulation functions {{{1
# munge {{{2
function munge()
{
    if [ $# -lt 2 ] ; then
        echo "munge <env-variable> <new-path> [after]"
        echo ""
        echo "See also: change_or_munge, and remove_path"
        return 1
    fi
    local var=$1
    # local val=$(eval echo \$$1)
    local val=${!1}

    _is_unset "${var}" && [[ "${verbose_munge}" = "1" ]] && _die "munge <env-variable> <new-path> [after]\n<env-variable> \$$1 does not exist." && return 1

    # linux -> egrep -q,
    # solaris -> egrep
    if [ -d "$2" ] ; then
        if ! echo $val | /bin/egrep -q "(^|:)$2($|:)" ; then
            if [ "$3" = "after" ] ; then
                eval $var=$(echo -ne \""$val:$2"\")
            else
                # echo $var=$2:$val
                eval $var=$(echo -ne \""$2:$val"\")
                # echo $var=$(eval echo \$$var)
            fi
        # else
        elif [ "${verbose_munge+set}" = "set" ] ; then
            echo "path already in $var ($2)"
        fi
    else
        if [[ "${verbose_munge+set}" = "set" ]] ; then
            echo "inexistent path not added to $var ($2)"
        fi
        return 2
    fi
    return 0
}

# change_or_munge {{{2
# replaces $2 by $3 in $1 unless it is not present. In that case, $3 is
# munged into $1
function change_or_munge()
{
    if [ $# -lt 2 ] ; then
        echo "change_or_munge <env-variable> <old-path> <new-path>"
        echo ""
        echo "See also: munge, and remove_path"
        return 1
    fi
    local var=$1
    # local val=$(eval echo \$$1)
    local val=${!1}
    _is_unset "${var}" && _die "change_or_munge <env-variable> <old-path> <new-path>\n<env-variable> \$$1 does not exist." && return 1
    local old=$2
    local new=$3
    # linux -> egrep -q,
    # solaris -> egrep
    if ! echo $val | /bin/egrep -q "(^|:)$2($|:)" ; then
        munge "$1" "$3" "$4"
    else
        # echo "replace $old with $new"
        val=$(echo $val | perl -pe "s#(^|:)$old(\$|:)#\\1$new\\2#")
        eval $var=$(echo -ne \""$val"\")
    fi
    echo $val | tr ':' '\n'
    return 0
}

# remove path {{{2
function remove_path()
{
    if [ ! $# -eq 2 ] ; then
        echo "remove_path <env-variable> <path-to-remove>"
        echo ""
        echo "See also: munge, and change_or_munge"
        return 1
    fi
    local var=$1
    # local val=$(eval echo \$$1)
    local val=${!1}
    _is_unset "${var}" && _die "remove_path <env-variable> <path-to-remove>\n<env-variable> \$$1 does not exist." && return 1
    local old=$2
    val=$(echo $val | perl -pe "s#(^|:)$old(\$|:)#\\1#;s#::#:#;s#^:|:\$##")
    eval $var=$(echo -ne \""$val"\")
    val=$(eval echo \$$var)
    echo $val | tr ':' '\n'
    return 0
}

# lh_test() {
    # echo "VAR=$1 VALUE=$(eval echo \$$1)"
# }

# ===========================================================================
# Paths cleaning {{{2
# apply a kind a O(n^2) uniq that clean duplicates
function clean_path()
{
    var=$1
    val=$(eval printf \$$1)
    declare -a dirs
    # dirs=(${val//:/ })
    # split at each element, supports pathnames containing whitepaces
    OLD=$IFS
    local  IFS=':'
    dirs=(${val})
    local IFS=$OLD

    declare -a res
    declare -a end=(${dirs[@]})
    while [ ${#end[@]} -gt 0 ]
    do
        crt=${end[0]}              # head
        end=("${end[@]:1}")        # tail
        # remove all occurrences of $crt in the tail ($end)
        duplicate=0
        i=0
        while [ $i -ne ${#end[@]} ] ; do
            if [ "${end[$i]}" = "$crt" ] ; then
                unset end[$i]
                duplicate=1
            else
                i=$(($i+1))
            fi
        done
        if [ $duplicate -eq 0 ] ; then
            # echo "$crt"
            res=( "${res[@]}" "${crt}")
        fi
    done

    local  IFS=':'
    str="${res[*]}"
    local IFS=$OLD
    # echo $str
    eval $var=$(echo -ne \""$str"\")
    return 0
}

## Completion {{{1
function _munge()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    case $COMP_CWORD in
        1) COMPREPLY=( $(compgen -v ${cur}) ) ;;
        *) COMPREPLY=( $(compgen -d ${cur}) ) ;;
    esac
}
complete -F _munge munge
complete -F _munge remove_path
complete -F _munge change_or_munge

# vim:ft=sh:fdm=manual:
