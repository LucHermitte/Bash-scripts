#!/bin/bash
# Inspired by http://stackoverflow.com/questions/3520936/accessing-bash-completions-for-specific-commands-programmatically
# Licence: CC-BY-NC-SA

## Helper functions {{{1
# __print_completions() {{{2
__print_completions() {
    printf '%s\n' "${COMPREPLY[@]}" | sort
}

# _die {{{2
function _die()
{
   local msg=$1
   [ -z "${msg}" ] && msg="Died"
   # printf "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: ${FUNCNAME[1]}: ${msg}" >&2
   printf "${msg}" >&2
   exit 0
}

command=$1

## Main code {{{1
# load bash-completion functions
source /etc/bash_completion

# load command completion function
_completion_loader ${command}
compl_def=$(complete -p ${command})
policy="${compl_def/complete -F /}"
[ "${policy}" != "$compl_def" ] || _die "Forwarding completion for this type of command isn't supported yet"
pol_tokens=(${policy})
[ ${pol_tokens[1]} == "${command}" ] || _die "Unexpected situation"

COMP_LINE="$@"
COMP_WORDS=("$@")
COMP_POINT=${#COMP_LINE}
((++COMP_POINT))
COMP_CWORD=1
${pol_tokens[0]}
__print_completions

# }}}1
# vim:ft=sh:fdm=marker
