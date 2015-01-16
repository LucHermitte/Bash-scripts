## SSH
SSH_ENV="$HOME/.ssh/environment"

# start the ssh-agent
function start_agent {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    rm "$SSH_ENV"
    ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
    echo succeeded
    chmod 600 "$SSH_ENV"
    . "$SSH_ENV" > /dev/null
    ssh-add
}

# test for identities
function test_identities {
    # test whether standard identities have been added to the agent already
    ssh-add -l | grep "The agent has no identities" > /dev/null
    if [ $? -eq 0 ]; then
        ssh-add
        # $SSH_AUTH_SOCK broken so we start a new proper agent
        if [ $? -eq 2 ];then
            start_agent
        fi
    fi
}

function _ssh_test_agent {
    ps -ef | grep $SSH_AGENT_PID | grep ssh-agent > /dev/null
}

function _ssh_run_env {
    # if $SSH_AGENT_PID is not properly set, we might be able to load one from
    # $SSH_ENV
    . "$SSH_ENV" > /dev/null
    _ssh_test_agent && test_identities || start_agent
}

# check for running ssh-agent with proper $SSH_AGENT_PID
[ -n "$SSH_AGENT_PID" ] && _ssh_test_agent \
&& test_identities \
|| _ssh_run_env

return

# This (old) version generates the following error message:
#  Usage : grep [OPTION]... PATTERN [FILE]...
ps -ef | grep $SSH_AGENT_PID | grep ssh-agent > /dev/null
if [ $? -eq 0 ]; then
    test_identities
# if $SSH_AGENT_PID is not properly set, we might be able to load one from
# $SSH_ENV
else
    . "$SSH_ENV" > /dev/null
    ps -ef | grep $SSH_AGENT_PID | grep ssh-agent > /dev/null
    if [ $? -eq 0 ]; then
        test_identities
    else
        start_agent
    fi
fi
