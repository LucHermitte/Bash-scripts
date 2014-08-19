#!/bin/sh

# A (b)ash script replacement for ps showing threads and other helpful stuff.
# Especially useful for Busybox based systems which has a very simple ps applet
#
# License: GPLv2
# Copyright 2009 Chris Simmonds, 2net Ltd
# chris@2net.co.uk

# See http://2net.co.uk/tutorial/list_threads

show_details ()
{
	# Read the stat entry for this process/thread. See man 5 proc for description
	read _PID _COMM _STATE _PPID _PGRP _SESSION _TTY_NR _TPGID _FLAGS _MINFLT _CMINFLT _MAJFLT \
	     _CMAJFLT _UTIME _STIME _CUTIME _CSTIME _PRIORITY _NICE _NUM_THREADS _IRETVALUE \
	     _STARTTIME _VSIZE _RSS _RSSLIM _STARTCODE _ENDCODE _STARTSTACK _KSTKESP _KSTKEIP \
	     _SIGNAL _BLOCKED _SIGIGNORE _SIGCATCH _WCHAN _NSWAP _CNSWAP _EXIT_SIGNAL _PROCESSOR \
	     _RT_PRIORITY _POLICY _JUNK < /proc/$PID_TO_SHOW/stat

	# Decode policy and priority
	case $_POLICY in
	"0")
		POLICY="TS"
		RTPRIO="- "
		;;
	"1")
		POLICY="FF"
		RTPRIO=$_RT_PRIORITY
		;;
	"2")
		POLICY="RR"
		RTPRIO=$_RT_PRIORITY
		;;
	*)
		POLICY="??"
		RTPRIO="- "
	esac
	# _WCHAN is the address of the kernel function the task is blocked
	# in: not much use, so read /proc/NN/wchan to get the name of the function
	read _WCHAN < /proc/$PID_TO_SHOW/wchan

	# The output is more or less equivalent to "ps -Leo pid,tid,class,rtprio,stat,comm,wchan"
	echo -e "$PID\t$TID\t$POLICY\t$RTPRIO\t$_STATE\t$_COMM\t$_WCHAN"

	# Of course, you can easily change the line above to output more or less information
	# Here is an example which adds nice, vsize and rss
	# echo -e "$PID\t$TID\t$POLICY\t$RTPRIO\t$_NICE\t$_STATE\t$_VSIZE\t$_RSS\t$_COMM\t$_WCHAN"

}

# Print banner. If you change show_details() to output more (or different)
# information, change this as well so you know what is what
echo -e "PID\tTID\tCLS\tRTPRIO\tSTAT\tCOMMAND\tWCHAN"
# echo -e "PID\tTID\tCLS\tRTPRIO\tNICE\tSTAT\tVSIZE\tRSS\tCOMMAND\tWCHAN"

# Get a list of processes from /proc

# Doing it like this gives a numerical listing. The simpler "for p in /proc/[0-9]*"
# would give an alphabetic list in which 2 comes after 10 rather than before.
# N.B. Assumes PIDs are 5 digits or fewer (check /proc/sys/kernel/pid_max)
for p in /proc/[0-9] /proc/[0-9][0-9] /proc/[0-9][0-9][0-9] /proc/[0-9][0-9][0-9][0-9] /proc/[0-9][0-9][0-9][0-9][0-9]; do
	PID=$(basename $p)
	if [ -f /proc/$PID/stat ]; then
		TID=$PID
		PID_TO_SHOW=$PID
		show_details

		# Look in /proc/NNNN/task for a list of threads
		for t in $p/task/*; do
			TID=$(basename $t)
			if [ $TID != $PID ]; then
				PID_TO_SHOW=$TID
				show_details
			fi
		done
	fi
done
