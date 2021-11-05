#!/bin/bash

PEGASO_START_SCRIPT_PWD=$(pwd)

# this is a code snipped:
# from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
# to understand what directory it's stored in bash script itself

PEGASO_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$PEGASO_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  PEGASO_DIR="$( cd -P "$( dirname "$PEGASO_SOURCE" )" && pwd )"
  PEGASO_SOURCE="$(readlink "$PEGASO_SOURCE")"
  [[ $PEGASO_SOURCE != /* ]] && PEGASO_SOURCE="$PEGASO_DIR/$PEGASO_SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
PEGASO_SCRIPT_DIR="$( cd -P "$( dirname "$PEGASO_SOURCE" )" && pwd )"
PEGASO_SCRIPT_FILE=$(basename "$PEGASO_SOURCE")
# end of snipped

cd "$PEGASO_SCRIPT_DIR"
cd .. || exit 1
export PEGASO_ROOT="$(pwd)"

PEGASO_PARENT_ROOT="$(dirname "$PEGASO_ROOT")"

# echo "$PEGASO_ROOT"
# echo "$PEGASO_PARENT_ROOT"

################# LOGGING FACILITY #####################
# from https://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
#
declare -A term_colors=( ["black"]='\033[0;30m' ["red"]='\033[0;31m' ["green"]='\033[0;32m' ["yellow"]='\033[0;33m' ["purple"]='\033[0;35m' ["reset"]='\033[0m' )
### from 0 (silent) to 6 (debug)
declare -A log_level2n=( ["any"]=0 ["force"]=0 ["silent"]=0 ["sil"]=0 ["s"]=0 ["o"]=0 ["output"]=0 ["crit"]=1 ["critical"]=1 ["c"]=1 ["error"]=2 ["err"]=2 ["e"]=2 ["warning"]=3 ["warn"]=3 ["w"]=3 ["notif"]=4 ["notification"]=4 ["n"]=4 ["info"]=5 ["information"]=5 ["i"]=5 ["informational"]=5 ["debug"]=6 ["d"]=6)
declare log_n2str=("OUTPUT" "CRITICAL" "ERROR" "WARNING" "NOTIFIC" "INFO" "DEBUG")
declare log_n2pad=("  "     ""         "   "   " "       " "      "    " "   ")
declare log_n2color=("reset" "purple" "red" "yellow" "green" "reset" "reset")
declare log_n2fd_1=(1 1 1 1 1 1 2) # write all to stdout, and debug to stderr;
declare log_n2fd_2=(3 3 3 3 3 3 3) # write all to /dev/null
# log_source_short_info is for optimize time
unset log_source_short_info
declare -A log_source_short_info
log_level=5
log_source_info=N
function log_level_assert() { # return numeric level on successful or 255 on fail; usedo to check if we have to log or not
    local level="$1"   
    local n_level=${log_level2n[$level]?}
    if [ $log_level -ge $n_level -o $n_level == 0 ]; then
	return $n_level # successfull
    fi
    return 255 # unsuccessfull, false
}
function log() { 
    log_level_assert "$1"
    local n_level=$?
    test $n_level == 255 && return 0
    shift
    local fd1=${log_n2fd_1[$n_level]?}
    local fd2=${log_n2fd_2[$n_level]?}
    if [ -n "$log_date_format" ]; then
	echo -n $(date "+$log_date_format")"|" >&$fd1 >&$fd2
    fi
    echo -e -n ${term_colors[${log_n2color[$n_level]}]}${log_n2str[$n_level]}${term_colors[${log_n2color[reset]}]}"${log_n2pad[$n_level]}|" >&$fd1 >&$fd2
    if [ -n "${log_source_format}" ]; then
	local k="${BASH_SOURCE[1]}"
	local short="${log_source_short_info[$k]}"
	if [ -z "$short" ]; then
	    short="$(basename "$k")"
	    log_source_short_info[$k]="$short"
	else
	    short="${log_source_short_info[$k]}"
	fi
	local sinfo=${log_source_format/"%S"/"$short"}
	sinfo=${sinfo/"%L"/"${BASH_LINENO[0]}"}
	sinfo=${sinfo/"%F"/"${FUNCNAME[1]}"}
	echo -n "$sinfo|" >&$fd1 >&$fd2  # $short:${BASH_LINENO[0]} ${FUNCNAME[1]}|"
    fi
    echo "$@" >&$fd1 >&$fd2
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
function log_set_fd () { # primary|secondary <fd> [<level1> [<level2> ... ]] : set levels to log to the given new file descriptor id; if no level given, all levels are processed
    local class="$1"
    if [[ $class != "primary" && $class != "secondary" ]] ;then
	log warn "log_set_fd: passed bad class=$class, ignoring"
    fi
    local fd="$2"
    if [[ ! $fd =~ ^[0-9]+$ ]]; then # if is a number
	log warn "log_set_fd: passed fd=$fd not a number, ignoring"
    fi
    shift
    shift
    local n=    
    if [ $# -gt 0 ]; then
	for level in $*; do
	    n=${log_level2n[$level]?}
	    case $class in
		primary)
		    log_n2fd_1[$n]="$fd"
		    ;;
		secondary)
		    log_n2fd_2[$n]="$fd"
		    ;;
	    esac
	done
    else # if no level, process all:
	case $class in
	    primary)
		log_n2fd_1=($fd $fd $fd $fd $fd $fd $fd)
		;;
	    secondary)
		log_n2fd_2=($fd $fd $fd $fd $fd $fd $fd)
		;;
	esac
    fi
}
function log_init() {
    # needed for secondary log. fd 3 goes to /dev/null by default
    exec 3>/dev/null
    log debug "log_init(): fd2=$fd2"
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
################# DEBUG AND STACK TRACE  #####################
# snipped from : 
# http://stackoverflow.com/questions/685435/bash-stacktrace
function unix_stack_trace () { # param is the log level
    log_level_assert "$1"
    test $? == 255 && return 0
    
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
    echo "Unix process backtrace (PID+command line): $TRACE" >&2
    # echo -en "$TRACE" | tac | grep -n ":" # using tac to "print in reverse" [3]	
}
# snipped from : 
# http://stackoverflow.com/questions/685435/bash-stacktrace
function bash_stack_trace() { # param is the log level
    log_level_assert "$1"
    test $? == 255 && return 0
    
    local STACK=""
    # to avoid noise we start with 1 to skip get_stack caller
    local i
    local stack_size=${#FUNCNAME[1]}
    for (( i=1; i<$stack_size ; i++ )); do
        local func="${FUNCNAME[$i]}"
        [ x$func = x ] && func=MAIN
        local linen="${BASH_LINENO[(( i - 1 ))]}"
        local src="${BASH_SOURCE[$i]}"
        [ x"$src" = x ] && src=non_file_source
        STACK+=$'\n'"   "$func" "$src":"$linen
    done
    STACK+=$'\n';
    echo "STACK TRACE of \$\$=$$ BASHPID=$BASHPID ${STACK}" >&2    
}
################# TEMPORARY FILES + CLEANUP #####################
unset mktemp_stack
declare mktemp_stack=()
# this function execute mktemp(1) passing parameters
# and store filename in order to be clen up at the end of the program.
# first parameter is the variable to write the output of mktemp(1)
WRAP_MKTEMP=
function wrap_mktemp() {
    local var="$1"
    local F
    shift
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

# set a date format for logging, see command date(1)
log_date_format="%Y-%m-%d %H:%M:%S"
log_date_format="%H:%M:%S"
# to disable date format for logging, set it to empty:
# log_date_format=""

# log_source_info contains format in % style to print source code
# information: %S (source filename) %L (line number) %F (function name)
# if empty, disable source info print. ONLY UPPERCASE LETTERS!
log_source_format="%S:%L %F"
# log_source_format=""

# set log level:
log_level debug
# read log level back:
# log silent $(log_level)

# another way to read it back:
# log silent DUMP: $(dumpvar log_level)

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


####################### BEGIN YOUR SCRIPT AFTER HERE ##################

# DEMO CODE: 
log_init 3

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

# now change some fd to log to different files:
out=debug.log
exec 4> $out
log_set_fd 4 debug
log notif "this is notification, do not goes to 4"
log debug "debugging goes to 4"
log_set_fd 4 debug notif info warn
log warn "this warn goes to 4"
log notif "this notif goes to 4"
log info "this info goes to 4"

echo "-----$out----------"
cat $out
echo "---------------"

log_set_fd 2 # now log all to stderr
log silent "this silent goes to stderr"
log warn "this warn goes to stderr"


wrap_mktemp
tmp1=$WRAP_MKTEMP
wrap_mktemp -d
tmp3=$WRAP_MKTEMP
echo $tmp1 $tmp2
echo ls -l $tmp1 $tmp2

abort 3 "now abort"
