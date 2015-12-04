

FUNCJOIN="__"
function func_info () {
    perl -e '$fj=shift;$_=shift;s/$fj/ /og;print "$_ "; while($_=shift) { print "$_ "; }' ${FUNCJOIN} $*
    echo
}
function func_search () {
    local func_prefix="${1}${FUNCJOIN}"
    echo "Available (sub)functions are:"
    env FJ=${FUNCJOIN} perl -ne "BEGIN { \$fj=\$ENV{FJ}; } if (/^function\\s+$func_prefix([a-zA-Z0-9_]+)\\s*\\(/o ) { \$_=\$1; if(!/\$fj/o) { print \"\\t\$_\\n\"; } }"  <  "$BASH_SCRIPT_DIR"/"$BASH_SCRIPT_FILE" | sort    
}
function func_call () {
    local func_prefix="${1}"
    local func_postfix="$2"
    local ret=0
    if [ $# = 1 ]; then 
	func_search $func_prefix
	return 0
    fi
    shift
    shift
    ${func_prefix}${FUNCJOIN}${func_postfix} $*
    ret=$?
    if [ $ret = 127 ]; then
#	echo "cannot find command: "
#	func_info ${func_prefix}${FUNCJOIN}${func_postfix}
	func_search ${func_prefix}
    fi
    return $?
}
