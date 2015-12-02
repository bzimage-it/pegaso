
# =========================================================================
#                               GENERAL PURPOSE SETTING
# =========================================================================


PERL_BIN=/usr/bin/perl

# =========================================================================
#                               GENERAL PURPOSE FUNCTIONS
# =========================================================================


# meta-evaluation of ARRAY[IDX] expression 
function eval_var_idx () {
    local varname="$1"
    local idx="$2"
    eval "echo \${$varname[$idx]:?}" 
}


# test an expression to be defined, if failed write $2 on stderr and exit(1)
# $1 : assertion expression to be tested via 'test -z'
# $2 : error message
function pegaso_assert_def () {
    test -z "$1" && echo "$2" 1>&2 && exit 1
}

# test an assertion, if failed write $2 on stderr and exit(1)
# $1 : assertion expression to be tested via 'test'
# $2 : error message
function pegaso_assert () {
    test $1 
    test $? != 0 && echo "$2" 1>&2 && exit 1
}

# test two expr $1,$2 to be equal, if failed write $3 on stderr and exit(1)
# this a low level funtion
# $1 : assertion expression to be tested via 'test'
# $2 : error message
function pegaso_assert_eq () {
    test "$1" == "$2"
    test $? != 0 && echo "$3" 1>&2 && exit 1
}


function ask_confirmation_yes () {
    local RISP=
    read  -p "$* [yes/no]" RISP
    if [ "$RISP" = "yes" ]; then
	return 0
    else
	return 1
    fi
}

function ask_choose_enum () {
    # write to std error a list op possibile options in <opt>
    # until user choose one
    # each param is in the form <opt>[:<description>]
    local ok=n
    local n=0
    local O=
    local header="$1"
    local RISP=
    shift
    while [ $ok == n -o $# == 0 ]; do
	let n+=1
	if [ $(($n % 10)) == 1 ]; then
	    echo "------------- $header ------------" 1>&2
	    for O in "$@"; do
		printf "%10s | %s\n" "${O%:*}" "${O#*:}" 1>&2
		
	    done
	    echo "------------- $header ------------" 1>&2
	fi
	read -e -p ">>> " RISP
	for O in $*; do
	    test "$RISP" == "${O%:*}" && ok=y
	done
    done
    echo $RISP
}


function safe_rm_rf_dir () {
    local dir="$1"
    local base=
    local dirname=
    if [ -d "$dir" ]; then
	dirname="$(dirname "$dir")"
	base="$(basename "$dir")"
	if [ "$dirname" != "$dir" ]; then
	    (cd "$dirname" &&
		rm -rf "$base" ) && return $?;
	else
	    return 10
	fi
    else
	if [ -e "$dir" ]; then
	    return 11
	fi
    fi
    return 0
}


function safe_rm_rf_dir_progress () {
    local PROGRESS_CHARS="$1"
    local DIR="$2"
    shift
    shift

    local BASERMDIR=
    local RMDIR=
    local count=0

    local tmp_rmbuild=$(new_tmp_file rm_build tmp)
    local tmp_count=$(new_tmp_file safe_rm_rf_dir_progress tmp)

    find "$DIR" $* | sort -r > $tmp_rmbuild
    local NDIR=$(cat "$tmp_rmbuild" | wc -l)

    log INFO "Removing ${DIR} ..."    
    echo "count=$count" > $tmp_count
    cat "$tmp_rmbuild" | while read RMDIR ; do 
	BASERMDIR="$(basename "${RMDIR}")"
	source $tmp_count

	safe_rm_rf_dir ${RMDIR} || abort_if_err "error removing ${RMDIR}"
	printf "\r%-30s %5d/%5d %s" "$BASERMDIR" $count $NDIR "$(progress $PROGRESS_CHARS $NDIR $count)"

	let count+=1
	echo "count=$count" > $tmp_count
    done
    BASERMDIR="$(basename "${DIR}")"
    safe_rm_rf_dir ${DIR} || abort_if_err "error removing ${DIR}"
    printf "\r%-30s %5d/%5d %s" "$BASERMDIR" $NDIR $NDIR "$(progress $PROGRESS_CHARS $NDIR $NDIR)"
    rm -f $tmp_rmbuild $tmp_count
}


function dump_env () {
    while [ $# -gt 0 ]; do
	echo -n $1"="
	eval echo \$$1
	shift
    done
}

function dump_env_local () {
    while [ $# -gt 0 ]; do
	echo $1"="$2
	shift
	shift
    done
}

function log_env () {
    local level="$1"
    shift
    log $level "VARIABLE DUMP$(echo)" "$(dump_env $*)"
}

# =========================================================================
#                               TEMP FILES/DIR FUNCTIONS:
# ========================================================================


function new_tmp_file () {
    local opt=""
    if [ -n "$1" ]; then
	opt="$1."
    fi
    opt="${opt}XXXXXXX"
    if [ -n "$2" ]; then
	opt="${opt}.$2"
    fi
#    log DEBUG tempfile $opt
    mktemp --tmpdir "$opt"
}

function new_tmp_dir () {
    mktemp -d --tmpdir "$1.XXXXX"
}


# =========================================================================
#                               LOG FUNCTIONS
# =========================================================================

declare -A LOG_LEVEL2N

LOG_LEVEL2N["DEBUG"]=6
LOG_LEVEL2N["TRACE"]=5
LOG_LEVEL2N["INFO"]=4
LOG_LEVEL2N["WARN"]=3
LOG_LEVEL2N["ERROR"]=2
LOG_LEVEL2N["FATAL"]=1
LOG_LEVEL2N["OUT"]=0

# this can be re-defined in some ohter place later:
CURRENT_LOG_LEVEL="DEBUG"
CURRENT_OUT_LEVEL="DEBUG"
# CURRENT_LOG_FILE="$ROOT_INTEGRATION_ENV/log/make.log"

function log_set_file {
	local F="$1";
	local NOW=$(date "+%Y-%m-%d %H:%M:%S");
	if [ "${F:0:1}" != "/" ] ; then
		F="$(pwd)/$F"
	fi
	if [ $? == 0 ]; then
		CURRENT_LOG_FILE="$F"
		return 0
	fi
	return 1
}

function log_restart {
	echo "$NOW - Started log for $0" > "$CURRENT_LOG_FILE"
}


# snipped from : 
# http://stackoverflow.com/questions/685435/bash-stacktrace
function unix_stack_trace () {
    local TRACE=""
    local CP=$$ # PID of the script itself [1]
    local CMDLINE=
    local tmp=
    local PP=
    local platform=$(get_platform_type)
    while true # safe because "all starts with init..."
    do
	if [ "$CP" == "1" -a "$platform" == 'cygwin' ]; then 
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
function bash_stack_trace() {
    # first print bash function  stack trace:
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


unset LOG_BASH_SOURCE_SHORT
declare -A LOG_BASH_SOURCE_SHORT

function log {
    local LEVEL_orig="$1"
    local LEVEL="[$LEVEL_orig]"
    printf -v LEVEL "%-7s" $LEVEL
    shift
    local NOW=$(date "+%Y-%m-%d %H:%M:%S");

    local k="${BASH_SOURCE[1]}"
    local short="${LOG_BASH_SOURCE_SHORT[$k]}"
    if [ -z "$short" ]; then
	short="$(basename "$k")"
	LOG_BASH_SOURCE_SHORT[$k]="$short"
    else
	short="${LOG_BASH_SOURCE_SHORT[$k]}"
    fi

    if [ ${LOG_LEVEL2N[$LEVEL_orig]:?} -le ${LOG_LEVEL2N[$CURRENT_LOG_LEVEL]:?} ]; then
	echo "$NOW $LEVEL [$short:${BASH_LINENO[0]} ${FUNCNAME[1]}] $*" >> "$CURRENT_LOG_FILE"
    fi
    if [ ${LOG_LEVEL2N[$LEVEL_orig]:?} -le ${LOG_LEVEL2N[$CURRENT_OUT_LEVEL]:?} ]; then
	echo "$LEVEL $*"
    fi
    if [ "$LEVEL_orig" == "FATAL" ]; then
	if [ "$CURRENT_OUT_LEVEL" == DEBUG ]; then
	    bash_stack_trace	
	    unix_stack_trace
	fi 
	exit 1
    fi
}




# =========================================================================
#                               EXTERNAL VAR/DIR FUNCTIONS
# =========================================================================


declare -A VAR_DIR

function set_var_dir {
	local WHERE="$1"
	local DIR="$2"
	VAR_DIR[$WHERE]="$DIR"
	mkdir -p "$DIR"
	# VAR_DIR_MODE="$WHERE"
}


function write_var {
	local WHERE="$1"
	local NAME="$2";
	local VAL="$3";
	local F="${VAR_DIR[$WHERE]}/$NAME.sh.var"
	# echo "--- $F"
	echo "$NAME=\"$VAL\"" > "$F"
	echo "log TRACE READ_VAR:$WHERE:$NAME=\"\$$NAME\"" >> "$F"
	log TRACE "WRITE_VAR:$WHERE:$NAME <- \"$VAL\""
}

function read_var {
	local WHERE="$1"
	local NAME="$2";
	local DEFAULT="$3";
	# set_var_dir $WHERE
	mkdir -p "${VAR_DIR[$WHERE]}"
	local F="${VAR_DIR[$WHERE]}/$NAME.sh.var"
	# echo "--- $F"
	if [ ! -f "$F" ]; then
		if [ -n "$DEFAULT" ]; then
			log TRACE "-- write default $F";
			write_var $WHERE $NAME "$DEFAULT"
		else
			log FATAL cannot read_var: $WHERE $NAME
		fi
	fi
	source "$F"
}


function write_var2 {
	local NAME="$1";
	local VAL="$2";
	local D="${TMPDIR:?}/read_var2/$$"
	mkdir -p $D && echo "$NAME=\"$VAL\"" > "$D/$NAME.sh.var2"
}

function read_var2 {
	local NAME="$1";
	local DEFAULT="$2";
	local F="${TMPDIR:?}/read_var2/$$/$NAME.sh.var2"
	if [ ! -f "$F" ]; then
	    if [ -n "$DEFAULT" ]; then
#		log TRACE "-- write default $F";
		write_var2 $NAME "$DEFAULT"
	    else
		log FATAL cannot read_var2: $NAME
	    fi
	fi
	source "$F"
}






# =========================================================================
#                               FILE RELATED FUNCTIONS
# =========================================================================


function file_size_of() {
	stat -c "%s" "$1"
}

# =========================================================================
#                               OTHER 
# =========================================================================


function scripts_set_env () {
	
	local scripts_base_name="$1"
	DIR_APP_SPEC="$SRC/$APP_SPEC"
	if [ ! -d "$DIR_APP_SPEC" ]; then
	    mkdir "$DIR_APP_SPEC" || abort_if_err
	fi


	SCRIPTS_BASE_NAME="$scripts_base_name"
	TARGET="$DIR_APP_SPEC/$scripts_base_name"

	SCRIPTS="$TARGET/scripts"
	PRJ="$TARGET/$L_PRJ"
	
	if [ -n "$2"  ]; then
		OUT="$2"
		if [ ! -d "$OUT" ]; then
			log FATAL "$OUT is not a dir"
		fi
		log TRACE "OUT set to $OUT"
	fi
	
}


# =========================================================================
#                      TERMINAL RELATED FUNCTIONS (use ncurses)
# =========================================================================


# sequences from http://www.termsys.demon.co.uk/vtansi.htm
declare -A TERMC
TERMC[erase_line]="\033[2K"
TERMC[erase_end_of_line]="\033[K"
TERMC[enable_line_wrap]="\033[7h"
TERMC[disable_line_wrap]="\033[7l"

function term() {
	echo -e ${TERMC["$1"]}
}

function printf_char_n() {
 local str=$1
 local n=$2
 test "$n" == 0 && return
 local v=$(printf "%-${n}s" "$str")
 echo -n "${v// /$str}"
}

function pegaso_progress() {
    local total_char=$1
    local total=$2
    local n=$3

    local na=
    local nb=
    local perc=
    let na="($total_char*$n)/$total"
    let perc="(100*$n)/$total"
    let nb="$total_char-$na"
#    echo "na=$na nb=$nb perc=$perc"
    printf "["
    printf_char_n '=' $na
    printf ">"
    printf_char_n ' ' $nb
    printf "%3d%%]" $perc    
}

# =========================================================================
#                      DATE AND TIME RELATED FUNCTIONS 
# =========================================================================


function pegaso_now() {
	date +%Y-%m-%d_%H-%M-%S
}
function pegaso_now_s () {
	date +%s
}



function pegaso_df_field () {
    local P="$1"
    local N="$2"    
    local OPTS="$3"
    if [ -z "$P" ]; then
	P="/"
    fi
    if [ -z "$N" ]; then
	P="4"
    fi
    df $OPTS "$P" | tail -n 1 | N="$2" perl -ne '@a=split/\s+/; $_=$a[$ENV{N}];s/\%$//;print;'
}


function pegaso_df_free_less_then_mega () {
    local mount_point="$1"
    local limit_mega="$2"
    local ret=0
    local free_size=
    free_size=$(df_field $mount_point 3 "-B"$((1024*1024)) )    
    if [ "$free_size" -gt "$limit_mega" ]; then
	log INFO "$mount_point : free $free_size is over of $limit_mega"
	ret=1
    else
	log INFO "$mount_point : free $free_size is less then $limit_mega"
    fi
    return $ret
}


# find for a quasi-random file in a directory tree:
function pegaso_find_random_file () {
    local tmp=$(new_tmp_file find_random_file tmp)
    local ROOT="$1"; 
    local TARGET="$ROOT"
    local FILE=""; 
    local n=
    local r=
    while [ -e "$TARGET" ]; do 
	TARGET="$(readlink -f "${TARGET}/$FILE")" ; 
#	echo -n "$TARGET - "
	if [ -d "$TARGET" ]; then
	    ls -1 "$TARGET" 2> /dev/null > $tmp || break;
	    n=$(cat $tmp | wc -l); 
	    if [ $n != 0 ]; then
		FILE=$(shuf -n 1 $tmp); 
#		r=$(($RANDOM % $n)) ; 
#		FILE=$(tail -n +$(( $r + 1 ))  $tmp | head -n 1); 
	    fi ; 
	else
	    if [ -f "$TARGET"  ] ; then
		rm -f $tmp
		echo $TARGET
		return 0;
	    else 
		# is not a regular file, restart:
		TARGET="$ROOT"
		FILE=""
	    fi
	fi
    done; 
    return 1
}
