#!/bin/bash
# Note: for bash only!
# ======================================================================
# AUTHOR:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
#               <URL:http://github.com/LucHermitte/Bash-scripts/>
#               <URL:http://hermitte.free.fr/cygwin/cyg-wrapper.sh>
#               <URL:http://www.vim.org/tips/tip.php?tip_id=381>
# CREDITS:      Jonathon M. Merz -> --fork option
#               Matt Armstrong   -> --cyg-env-... options
#               John Aldridge    -> For pointing me to "$COMSPEC /c start"
#               Matthias Morche  -> fix for scp://, http://, ... paths
#               Zhiguo Yao       -> Don't convert to DOS short form
#               Gilbert Goodwill -> Support of MSWindows' UNC pathes ; Support
#                                   for new behaviour of realpath
#               James Kanze      -> Patch for --fork=2
#
# LAST UPDATE:  13th Mar 2020
version="2.22"
#
# NOTES:   {{{1
#   IMPORTANT: this shell script is for cygwin *ONLY*!
#
#   This version requires cygUtils ; and more precisely: realpath (1).
#
#   Some versions previous to important changes in the script are still
#   avaible, see the history.
#
#   As bash will interpret backslashes before any program can see them, if you
#   want to pass pathnames containing backslashes, you will have to either
#   double the backslashes or to write them between a pair of (double or
#   single) quotes.
#
# PURPOSE: {{{1
#   This script wraps the calls to native win32 tools from cygwin. The
#   pathnames of the file-like arguments for the win32 tools are
#   translated in order to be understandable by the tools.
#
#   It converts any pathname into its windows (long) form.
#   Symbolic links are also resolved, whatever their indirection level is.
#
#   It accepts windows pathnames (relative or absolute) (backslashed or
#   forwardslashed), *nix pathnames (relative or absolute).
#
# USAGE:   {{{1

usageversion() {
    prog=`basename $0`
    usage="Usage: $prog PROGRAM [OPTIONS] [PROG-PARAMETERS...]"
    if [ $# = 0 ] ; then
        echo $usage >&2
        echo "       $prog -h|--help">&2
    else
        cat <<END
# $prog $version
Copyright (c) 2001-2020 Luc Hermitte
  This is free software; see the GNU General Public Licence version 2 or later
  for copying conditions.  There is NO warranty.

Purpose:
   This script wraps the calls to native win32 programs from cygwin.
   The pathnames of the file-like arguments for the win32 programs are
   translated in order to be understandable by the programs.

$usage
Parameters:
    PROGRAM
        Pathname to the native win32 program to execute.
        Must be specified in the DOS (short) form on MsWindows 9x systems.
    PROG-PARAMETERS
        List of parameters passed to PROGRAM.
Options:
    --slashed-opt
        Program-parameters expressed as '-param' will be converted to '/param'.
    --binary-opt=BIN-OPTIONS
        BIN-OPTIONS is a comma separated list of binary options for PROGRAM
        Only list options that are not expecting a file as the second element
        of the pair.
    --keywords=KEYWORDS
        KEYWORDS is a comma separated list of actions for PROGRAM. These
        actions are special commands that must not be interpreted as files.
    --path-opt=PATH-OPTIONS
        PATH-OPTIONS is a comma separated list of special options for PROGRAM.
        These options accept a path after an equal sign. The path will be
        converted if it points to a local file, or left unchanged if it is an
        URL-like path.
    --cyg-env-clear=ENV-VARS
        ENV-VARS is a comma separated list of environment variables to unset
        before executing PROGRAM. This is local to the execution of PROGRAM.
    --cyg-env-convert=ENV-VARS
        ENV-VARS is a comma separated list of environment variables. The
        pathnames expressed by these variables are converted to their Windows
        (long) form. This is local to the execution of PROGRAM
    --cyg-verbose[=VERBOSE-LEVEL]
        VERBOSE-LEVEL defaults to 0, 1 if --cyg-verbose is specified.
        >= 1 : Display the command really executed
        >= 2 : Display the values of the parameters given to cyg-wrapper
    --fork=<0, 1 or 2>
        0: (default) Does not fork the new process.  Can be used to override a
           previous --fork=1 argument.
        1: Forks the new process so the shell is still accessible.
        2: Forks the new process and makes it independent from the shell, so
           the shell is still accessible and can be dismissed.
           Note: this option wraps a call to "\$COMSPEC /c".

Typical use:
  The easiest way to use this script is to define aliases or functions.
  ~/.profile is a fine place to do so.

Examples:
  alias vi='cyg-wrapper.sh "C:/Progra~1/Edition/vim/vim70/gvim.exe"
        --binary-opt=-c,--cmd,-T,-t,--servername,--remote-send,--remote-expr'

  gvim() {
      opt=''
      if [ \`expr "\$*" : '.*tex\\>'\` -gt 0 ] ; then
          opt='--servername LATEX '
      fi
      cyg-wrapper.sh "F:/Progra~1/Edition/vim/vim70/gvim.exe"
         --binary-opt=-c,--cmd,-T,-t,--servername,--remote-send,--remote-expr
         --cyg-verbose --fork=2 \$opt "\$@"
  }

  alias explorer='cyg-wrapper.sh "explorer" --slashed-opt'

  alias darcs='cyg-wrapper.sh path/to/darc --keywords=get,changes,pull
         --path-opt=--repo'
END
    fi
}

if [ $# = 0 ] ; then
    usageversion
    exit 1
elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usageversion -h
    exit 0
fi

# HISTORY: {{{1
# A slower and older version not requiring cyg-utils is available at:
#     http://hermitte.free.fr/cygwin/cyg-wrapper-1.1.sh
#
# v 2.02
# (*) Uses cygUtils (actually realpath to determine where a file really is).
# (*) New option: --fork (thanks to Jonathon M. Merz)
# (*) New syntax for "binary options"
#
# v 2.03 -> 2.09
# (*) Bug fixes
# (*) Improvments regarding --fork
# (*) New options: --cyg-env-... (thanks to Matt Armstrong)
# (*) Don't try to convert scp://, http://, ftp://, ...
#     (thanks to Matthias Morche)
#   The version 2.09 which converts pathnames to their Windows short form is
#   still available at:
#     http://hermitte.free.fr/cygwin/cyg-wrapper-2.9.sh
#
# v 2.10
# (*) Converts pathnames to their Windows short form
# (*) Little speedup in the script ( ${var/pat/repl} is used instead of sed)
# (*) The way pathnames made of spaces has been enhanced
# (*) Don't convert to DOS short from anymore (thx to: Zhiguo Yao)
#
# v 2.11 -> 2.12
# (*) Support of MSWindows' UNC pathes (thx to: Gilbert Goodwill)
#
# v 2.13
# (*) First workaround to support parameters having spaces like in:
#     gvim -c "echo 'foo'"
#     However, ?gvim -c 'echo "foo"'? is not supported.
#   The version 2.13 which does not use Bash's arrays is still available at:
#     http://hermitte.free.fr/cygwin/cyg-wrapper-2.13.sh
#
# v 2.14
# (*) Full support of parameters having spaces, thanks to Bash's arrays.
#
# v 2.15
# (*) New option: --keywords
#
# v 2.16
# (*) I've get rid of the external program ?expr?, and now I use bash's
#     internal funtionalities to parse the arguments.
#     => significant speed-up
# (*) Convert parameters like: '--xxx={path}' -> new option: --path-opt
#
# v 2.17
# (*) Optional number for cyg-verbose
#
# v 2.18
# (*) The behaviour of realpath has changed. The script has been updated in
#     consequence.
#
# v.2.20
# (*) Convert PROGRAM into Windows form
#
# v2.22
# (*) Correctly decode binary options (See #6 reported by Tavish Robinson)
#
# }}}1
# TODO:    {{{1
# (*) Convert parameters like: 'X{path}'
# (*) --cyg-env-clear=HOMEPATH does not work while
#     --cyg-env-clear=PWD and --cyg-env-convert=HOMEPATH work... That's odd!
# (*) Convert some special lists of directories like $MANPATH (but is it really
#     useful ?)
# (*) Accept non DOS (short) form for PROGRAM
# (*) $COMSPEC /c start gvim is not working anymore
# (*) Enhance --keywords to support:
#     - the exact syntax of the program; e.g. the second ?cvf? in ?tar cvf cvf?
#       is a file, but not the first
#     - composed actions like with tar
#
# }}}1
# ======================================================================

## 0- Helper functions {{{1
# @brief  Function grealpath      {{{2
# @param  $1 may be a local path, or any URL <http://host> or <ftp://host>.
# @return What realpath should be returning: It is also resolves pathnames to
#         non yet existent files.
# @author Gilbert Goodwill provided this function after realpath behaviour was
# changed by its maintainers.
function grealpath()
{
    path=$1
    trim=

    # New realpath does not like non-existent paths
    val=`realpath "$path" 2>/dev/null`
    returned=$?
    # debug: echo returned=$returned 1>&2

    # While realpath is not succeeding, and not reached the top
    while ( [ $returned != 0 ] ) && ( [ $path != "/" ] ) && ( [ $path != ".." ] )
    do
        # Try the parent directory by trimming after last /
        newtrim=`basename "$path"`
        path=`dirname "$path"`
        # debug: echo trim=$trim 1>&2
        # If something new was trimmed add on to total trimmed
        if [ "X$trim" != "X" ]
        then
            trim=$newtrim/$trim
        else
            trim=$newtrim
        fi
        # debug: echo $path / $trim 1>&2

        # Try realpath again
        rpout=`realpath "$path" 2>/dev/null`
        returned=$?
        # debug: echo returned=$returned 1>&2
        # debug: echo rpout=$rpout 1>&2

        # If realpath was successful on the path, add back in the trimmed
        if ( [ $returned == 0 ] &&[ "X$rpout" != "X/" ] )
        then
            val=$rpout/$trim
        else
            val=/$trim
        fi
    done

    # Output the result of trimming the path with trimmed part tacked back on
    echo $val
}

# @brief  Function transform_path {{{2
# @param  $1 may be a local path, or any URL <http://host> or <ftp://host>.
# @return either the "win32" exact path for a possibly local file, or the
#         unmodified URL. A path is considered to be an URL when it matches
#         "[a-z]*://"
# @todo   Support <mailto:> and <news:>
transform_path() {
    if [ "${1/[[:lower:]]*:\/\//}" != "$1" ] ; then
        # Some netrw protocol like <http://host> or <ftp://host> : leave
        # unchanged
        echo "$1"
    else
        # Convert pathname "$1" to absolute path (*nix form) and resolve
        # all the symbolic links
        ptransl=`grealpath "$1"`
        ptransl=`cygpath -wl "$ptransl"`
        echo "$ptransl"
    fi
}


# ======================================================================
# I- Initializations: {{{1
# I.a- Default value for the various options {{{2
#
# Store the program name.
declare -a param=($(cygpath -ms "$1"))
shift;

# Special arguments:
# --slashed-opt  : says that the program expects parameters of the form '/opt'
# --binary-opt={opts} : lists of binary options whose 2nd element is not a file
# --keywords={acts} : lists of actions like in ?apt-get update?
# --path-opt={opts} : list of options taking a path after an equal sign
# --cyg-verbose  : forces echo of the command really executed
# --fork=<[0]|1|2> : explicitly forks the process
# --cyg-clear-env={vars} : lists of environment variables to unset
# --cyg-convert-env={vars} : lists of environment variables whose pathnames must
#                            be converted
slashed_opt=0
declare -A binary_args=()
keywords=""
path_options=""
cyg_verb=0
fork_option=0

# I.b- checks cyg-wrapper.sh's arguments {{{2
# Impl. note: ${1#*=} strips from $1 every character up to the equal sign.
while [ $# -gt 0 ] ; do
    case "$1" in
        --slashed-opt       ) slashed_opt=1;;
        --cyg-verbose=[0-9] ) cyg_verb=${1#*=};;
        --cyg-verbose       ) cyg_verb=1;;
        --binary-opt=*      ) IFS=, bargs=(${1#*=})
            declare -Ar binary_args="($(printf "[%s]=1 " "${bargs[@]}"))"
            ;;
        --path-opt=*        ) path_options=${1#*=};;
        --keywords=*        ) keywords=${1#*=};;
        --fork=[012]        ) fork_option=${1#*=};;
        --cyg-env-clear=*   )
            list=${1#*=}
            for i in ${list//,/ } ; do
                # This change is local to sub-processes only
                unset $i
            done
        ;;
        --cyg-env-convert=* )
            list=${1#*=}
            for i in ${list//,/ } ; do
                # Need to have access to ${$i} -> "eval ... '$'$i"
                eval val='$'$i
                # The environment variable may not exist (/be exported)
                if [ ! "$val" = "" ] ; then
                    val=`grealpath "$val"`
                    val=`cygpath -wl "$val"`
                    # This change is local to sub-processes only
                    declare $i="$val"
                fi
                # echo val[$i]=$val
            done
        ;;
        *) break;; # no shift!
    esac
    shift
done


if [ $cyg_verb -gt 1 ] ; then
    echo "cyg_verb      =$cyg_verb"
    echo "binary_args   =${bargs[@]}"
    echo "path_options  =$path_options"
    echo "keywords      =$keywords"
    echo "slashed_opt   =$slashed_opt"
    echo "fork_option   =$fork_option"
fi

# }}}1
# ======================================================================
# II- Main loop {{{1

# Loop that transforms PROGRAM's arguments {{{2
# For each argument ...
while [ $# -gt 0 ] ; do
    if [ -v binary_args[$1] ] ; then
        # Binary arguments: the next argument is to be ignored (not a file).
        [ $cyg_verb -gt 2 ] && printf "bin arg: '%s' '%s'\n" "$1" "$2"
        param[${#param[*]}]="$1"
        shift
        param[${#param[*]}]="$1"
    elif [ "${keywords/$1/}" != "$keywords" ] ; then
        # Actions: the argument is to be ignored (not a file).
        # Todo: check to position of the keywords
        [ $cyg_verb -gt 2 ] && printf "keyword: '%s'\n" "$1"
        param[${#param[*]}]="$1"
    elif [ "${path_options/${1%=*}/}" != "$path_options" ] ; then
        # Special option of the form: "{option}={path}"
        # echo -n "Found path opt"
        # echo " ($1 ; ${1%=*}) = <${path_options/${1%=*}/}> VS $path_options"
        #
        # Extract and tranform the path written after the equal sign.
        p=`transform_path "${1#*=}"`
        # Push the complete option with the "win32"/URL path ito the list of
        # parameter.
        [ $cyg_verb -gt 2 ] && printf "path opt: '$%s' <- '%s'\n" "${1%=*}" "$p"
        param[${#param[*]}]="${1%=*}=$p"
    else
        # Plain path or options.
        # echo "path opt ($1 ; ${1%=*}) = <${path_options/${1%=*}/}> VS $path_options"
        case "$1" in
            [-+]* ) # Option
                if [ $slashed_opt = 1 ] ; then
                    [ $cyg_verb -gt 2 ] && printf "opt: '%s'\n" "${1/-//}"
                    param[${#param[*]}]="${1/-//}"
                else
                    [ $cyg_verb -gt 2 ] && printf "opt: '%s'\n" "$1"
                    param[${#param[*]}]="$1"
                fi
            ;;

            *     ) # Plain path
                # NB: must be done in two steps in order to not break arguments
                # having spaces.
                p=`transform_path "$1"`
                [ $cyg_verb -gt 2 ] && printf "path: '%s' <- '%s'\n" "$p" "$1"
                param[${#param[*]}]="$p"
            ;;
        esac
    fi

    # Next!
    shift
done

# }}}1
# ======================================================================
# III- Execute the proper tool with the proper arguments. {{{1
# verbose
if [ $cyg_verb -gt 0 ] ; then
    # echo "$param"  | sed s'#\\\\#\\#g'
    # echo ${param//\\\\\\\\/\\}
    printf " '%s'" "${param[@]}"
fi
# call PROGRAM
# exit
if [ $fork_option = 1 ] ; then
    # `echo "$param" | xargs -t $xargs_param` &
    # WAS (2.13): eval $param &
    # eval "${param[@]}" &
    "${param[@]}" &
elif [ $fork_option = 2 ] ; then
    # That's very odd. This does not work anymore...
    # I do know if it comes from XP's last update or cygwin last update
    comspec=$(cygpath -u $COMSPEC)
    # WAS (2.13): eval $comspec /c start $param
    # eval $comspec /c start "${param[@]}"

    # (2.18)
    $comspec /c start "${param[@]}"

    # this seems to work, at least in my configuration (JAK, 28/4/2010)
    # $comspec /c "${param[@]}"

    # Other solutions rejected.
    # Be aware that cygstart accepts a very limited number of characters as
    # parameters, and that cygstart will steal ALL the parameters given to
    # PROGRAM, unless ?--? is used.
    # However, this solution is still working while $COMSPEC's one is not
    # cygstart -- "${param[@]}"
    # cygstart "${param[@]}"
    #
    # Other solution which seems to not work
    # "${param[@]}" <&0 &
    # disown
else
    # `echo "$param" | xargs $xargs_param`
    # WAS (2.13): eval $param
    # eval "${param[@]}"
    "${param[@]}"
fi
# }}}1
# ======================================================================
# vim600: set fdm=marker tw=79:
