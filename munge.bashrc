# ===========================================================================
## Paths list concatenations that avoid duplicates
# exemple:
# Script initially found in the /etc of a linux distribution, then
# patched by Luc Hermitte.
# Licence, likelly GPL v2. To be confirmed.
#
# $ munge PATH "$HOME/bin"
# $ munge MANPATH "$HOME/man"
# verbose_munge=1
munge() {
    if [ $# -lt 2 ] ; then
	echo "munge <env-variable> <new-path> [after]"
	return 1
    fi
    local var=$1
    local val=$(eval echo \$$1)
    if [[ "${val=set}" = "unset" && "${verbose_munge+set}" = "set" ]] ; then
	echo "munge <env-variable> <new-path> [after]"
	echo "$1 does not exist"
	return 1
    fi
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
	    echo "inexistant path not added to $var ($2)"
	fi
	return 2
    fi
}

# replaces $2 by $3 in $1 unless it is not present. In that case, $3 is
# munged into $1 
change_or_munge() {
    if [ $# -lt 2 ] ; then
	echo "change_or_munge <env-variable> <old-path> <new-path>"
	return 1
    fi
    local val=$(eval echo \$$1)
    if [ -z $val ] ; then
	echo "change_or_munge <env-variable> <old-path> <new-path>"
	echo "<env-variable> does not exist"
	return 1
    fi
    local var=$1
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
}

# remove path
remove_path() {
    if [ ! $# -eq 2 ] ; then
	echo "remove_path <env-variable> <path-to-remove>"
	return 1
    fi
    local val=$(eval echo \$$1)
    if [ -z $val ] ; then
	echo "remove_path <env-variable> <path-to-remove>"
	echo "<env-variable> does not exist"
	return 1
    fi
    local var=$1
    local old=$2
    val=$(echo $val | perl -pe "s#(^|:)$old(\$|:)#\\1#;s#::#:#;s#^:|:\$##")
    eval $var=$(echo -ne \""$val"\")
    val=$(eval echo \$$var)
    echo $val | tr ':' '\n'
}

# lh_test() {
    # echo "VAR=$1 VALUE=$(eval echo \$$1)"
# }

# ===========================================================================
## Paths cleaning
# apply a kind a O(n^2) uniq that clean duplicates
clean_path() {
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
}

# vim:ft=sh:
