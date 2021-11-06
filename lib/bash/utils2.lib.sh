#!/bin/bash

# this file can be both "sourced" via bash source command or
# included at the beginning of your script.
# 
# you may also be funny if you include "header.sh" too at the
# very beginning of your script.


################# LOGGING FACILITY #####################
# inspired from
# https://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
#
declare -A term_colors=( ["black"]='\033[0;30m' ["red"]='\033[0;31m' ["green"]='\033[0;32m' ["yellow"]='\033[0;33m' ["purple"]='\033[0;35m' ["reset"]='\033[0m' )
### from 0 (silent) to 6 (debug)
declare -A log_level2n=( ["any"]=0 ["force"]=0 ["silent"]=0 ["sil"]=0 ["s"]=0 ["o"]=0 ["output"]=0 ["crit"]=1 ["critical"]=1 ["c"]=1 ["error"]=2 ["err"]=2 ["e"]=2 ["warning"]=3 ["warn"]=3 ["w"]=3 ["notif"]=4 ["notification"]=4 ["n"]=4 ["info"]=5 ["information"]=5 ["i"]=5 ["informational"]=5 ["debug"]=6 ["d"]=6)
declare log_n2str=("OUT"      "CRIT"  "ERROR" "WARN"  "NOTIF" "INFO"  "DEBUG")
declare log_n2strpad=("OUT  " "CRIT " "ERROR" "WARN " "NOTIF" "INFO " "DEBUG")
declare log_n2color=("reset" "purple" "red" "yellow" "green" "reset" "reset")
declare log_n2fd=(1 1 1 1 1 1 1) # write all to stdout
unset log_source_short_info # for optimize execution time 
declare -A log_source_short_info
declare -i log_level=5 # set a starting level
declare -u log_source_info=N # source code information enable/disable; Y | N
declare -u log_on_bad_level=LOG # define the behavoir on log level param error; value: ABORT | FAIL | LOG (log as debug) | ERROR (log as error) | IGNORE
declare -u log_color_mode=Y # set color mode for level printing; Y | N
declare log_timestamp_format="%Y-%m-%d %H:%M:%S" # a date(1) format for logging
# log_source_info; set to empty string to disable
declare -u log_source_format="%s:%l %f" # contains format in % style to print source code; %s (source filename) %l (line number) %f (function name); if empty, disable source info print.
function log_level_assert() { # say wheather a log shall be done or not; return numeric level of the given level on successful (do log) or >=250 on fail (do not log); 
    local level="$1"
    if test ! -v log_level2n[$level] ; then
	case "$log_on_bad_level" in
	    ABORT)
		abort 1 "bad log level: $level"
		;;
	    FAIL)
		return 254;
		;;
	    LOG)
		log debug "error in given log level: $level"
		return 254;
		;;
	    ERROR)
		log error "error in given log level: $level"
		return 254;
		;;
	    *)
		return 250; # return error (to not to log) but do nothing
		;;
	esac
    fi
    local n_level=${log_level2n[$level]?}
    if [ $log_level -ge $n_level -o $n_level == 0 ]; then
	return $n_level # successfull
    fi
    return 255 # unsuccessfull, false
}
function log() {
    log_level_assert "$1"
    local n_level=$?
    test $n_level -ge 250 && return 0
    shift
    local fd1=${log_n2fd[$n_level]?}
    if [ -n "$log_timestamp_format" ]; then
	echo -n $(date "+$log_timestamp_format")"|" >&$fd1 
    fi
    if [ "$log_color_mode" == Y ]; then
	echo -e -n ${term_colors[${log_n2color[$n_level]}]}"${log_n2strpad[$n_level]}"${term_colors[reset]}"|" >&$fd1
    else
	echo -n "${log_n2strpad[$n_level]}|" >&$fd1
    fi
    if [ -n "${log_source_format}" ]; then
	local k="${BASH_SOURCE[1]}"
	local short=
	if [ ! -v "log_source_short_info[$k]" ]; then
	    short="$(basename "$k")"
	    log_source_short_info[$k]="$short"
	else
	    short="${log_source_short_info[$k]}"
	fi
	local sinfo=${log_source_format/"%S"/"$short"}
	sinfo=${sinfo/"%L"/"${BASH_LINENO[0]}"}
	sinfo=${sinfo/"%F"/"${FUNCNAME[1]}"}
	echo -n "$sinfo|" >&$fd1  # $short:${BASH_LINENO[0]} ${FUNCNAME[1]}|"
    fi
    echo "$@" >&$fd1 
}
function dumpvar () { for var in $@ ; do echo "$var=${!var}" ; done }
function log_level () { # set current logging level or print it if not given
    local level="$1"
    if [ -n "$level" ]; then
	log_level=${log_level2n[$level]?}
    else
	echo ${log_n2str[$log_level]?}
    fi
}
function log_set_fd () { #  <fd> [<level1> [<level2> ... ]] : set levels to log to the given new file descriptor id; if no level given, all levels are processed
    local fd="$1"
    if [[ ! $fd =~ ^[0-9]+$ ]]; then # if is a number
	log warn "log_set_fd: passed fd=$fd not a number, ignoring"
    fi
    shift
    local n=    
    if [ $# -gt 0 ]; then
	for level in $*; do
	    n=${log_level2n[$level]?}
	    log_n2fd[$n]="$fd"
	done
    else # if no level, process all:
	log_n2fd=($fd $fd $fd $fd $fd $fd $fd)
    fi
}
################# ABORT #####################
function abort () {
    # if first param is a number, assume is the exit code to return
    # (default=1). all the remaing args are passed to log function
    local code=1 # set default
    if [[ $1 =~ ^[0-9]+$ ]]; then # if is a number
	code=$1
	shift
    fi
    log critical "ABORT [exit code $code]" "$@" 
    exit $code
}
################# DEBUG AND STACK TRACE #####################
# snipped from : 
# http://stackoverflow.com/questions/685435/bash-stacktrace
function unix_stack_trace () { # param is the log level
    log_level_assert "$1"
    test $? -ge 250 && return 0
    
    local TRACE=""
    local CP=$$ # PID of the script itself [1]
    local CMDLINE=
    local tmp=
    local PP=
    local platform=$(uname -o)
    while true # safe because "all starts with init..."
    do
        if [ "$CP" == "1" -a "${platform^^}" == 'CYGWIN' ]; then 
	    break
        fi
        CMDLINE=$(cat /proc/$CP/cmdline | perl -ne 's/\x00/ /og;print;')
        PP=$(grep PPid /proc/$CP/status | awk '{ print $2; }') # [2]
        printf -v tmp "\n%10d   $CMDLINE" $CP
        TRACE+="$tmp"
        # $'\n'"   [$CP]:$CMDLINE"
        if [ "$CP" == "1" ]; then # we reach 'init' [PID 1] => backtrace end
	    break
        fi
        CP=$PP
    done    
    log "$1" "Unix process backtrace (PID+command line): $TRACE"
    # echo -en "$TRACE" | tac | grep -n ":" # using tac to "print in reverse" [3]	
}
# snipped from : 
# http://stackoverflow.com/questions/685435/bash-stacktrace
function bash_stack_trace() { # param is the log level
    log_level_assert "$1"
    test $? -ge 250 && return 0    
    local STACK=""
    # to avoid noise we start with 1 to skip get_stack caller
    local i
    local stack_size=${#FUNCNAME[@]}
    for (( i=1; i<$stack_size ; i++ )); do
        local func="${FUNCNAME[$i]}"
        [ x$func = x ] && func=MAIN
        local linen="${BASH_LINENO[(( i - 1 ))]}"
        local src="${BASH_SOURCE[$i]}"
        [ x"$src" = x ] && src=non_file_source
        STACK+=$'\n'"   "$func" "$src":"$linen
    done
    STACK+=$'\n';
    log "$1" "STACK TRACE of \$\$=$$ BASHPID=$BASHPID ${STACK}"
}
################# TEMPORARY FILES + CLEANUP #####################
unset mktemp_stack
declare mktemp_stack=()
# this function execute mktemp(1) passing parameters
# and store filename in order to be clen up at the end of the program.
# first parameter is the variable to write the output of mktemp(1)
# return created file name into WRAP_MKTEMP.
# DO NOT USE THIS FUNCTION AS SUBSHELL LIKE $(wrap_mktemp) !!
WRAP_MKTEMP=
function wrap_mktemp() {
    WRAP_MKTEMP=$(mktemp $*)
    mktemp_stack+=("$WRAP_MKTEMP")
    # echo "${mktemp_stack[@]}"
    log debug wrap_mktemp "$@" "-> $WRAP_MKTEMP"
}
function cleanup_temp() { 
    local F=
    for F in "${mktemp_stack[@]}"; do 
	rm -rf "$F" && log debug "cleanup $F"
    done
    mktemp_stack=()
}
#####################################################################
####################### USER CONFIGURATION VARIABLES ################
#####################################################################
# set variables, if different from defaults (see comment above):
log_timestamp_format="%H:%M:%S"
log_source_format="%s:%l %f"
log_on_bad_level=LOG

# set your log level:
log_level debug
# read log level back:
log silent $(log_level)

# another way to read it back:
log silent DUMP: $(dumpvar log_level)

# configure your 'traps' to exit cleanly:
trap on_exit EXIT QUIT

# configure your own 'on_exit' function. dont forget to call cleanup_temp()
function on_exit() {
    cleanup_temp
    
    # some other code here:
    # ...

    bash_stack_trace debug
    unix_stack_trace debug
}

# "set -u": althought not necessary is strongly suggested as defensive
# programming policy to many functions usgin ${xxxxx?} syntax.
# Also many bugs can be discovered easier.
set -u

####################### BEGIN YOUR SCRIPT AFTER HERE ##################
# DEMO CODE: 

log warn "this is a warning"
log err "this is an error"
log info "this is an information"
log notif "this is notification"
log debug "debugging"
log crit "CRITICAL MESSAGE!"

log_level info
log debug "XXXXXXXXXXXXX this shall not be logged"

log_level silent
log output "silent is always logged"

function stack_trace_demo() {
    bash_stack_trace any
}
stack_trace_demo

log_level warning
log warning "this is shoed 1"
log info "XXXXXXXXXXXXXXX this is not logged"
log_level debug

# testing temporary files management:
wrap_mktemp
tmp1=$WRAP_MKTEMP
wrap_mktemp -d
tmp2=$WRAP_MKTEMP
echo $tmp1 $tmp2
echo ls -l $tmp1 $tmp2

# now change some fd to log to different files:
exec 4> $tmp1
log_set_fd 4 debug
log_color_mode=N # disable color mode
log notif "this is notification, do not goes to 4"
log debug "debugging goes to 4"
log_set_fd 4 debug notif info warn
log warn "this warn goes to 4"
log notif "this notif goes to 4"
log info "this info goes to 4"
log_color_mode=Y # re-enable color mode

echo "----- $tmp1 ----------"
cat $tmp1
echo "---------------"

log_set_fd 2 # now log all to stderr
log silent "this silent goes to stderr"
log warn "this warn goes to stderr"
log_set_fd 1 # go back to log all to stdout

# now testing different values for log_on_bad_level:
log_level debug

log_on_bad_level=ignore
log eeeee1 "XXXXXXXXXXXXX this shall not logged"
log_on_bad_level=log
log eeeee2 "this shall be logged as bad level eeeee2 DEBUG"
log_on_bad_level=error
log eeeee3 "this shall be logged as bad level eeeee3 ERROR"
log_on_bad_level=fail
log eeeee4 "XXXXXXXXXX this shall not be logged"
log_on_bad_level=abort
log eeeee5 "XXXXXXXX this shall not be logged, but abort happens eeeee5"

# abort 3 "now abort"
