# this is a nice content to be inserted into ~/.bashrc file:
# you can also put this line at the end of ~/.bashrc:
# source /my-pegaso-root-dir/lib/bash/bashrc.lib.sh

# usefull to store a command in history without execute:
alias s='history -s '
t_DIR=$HOME
z_DEFAULT_FORMAT="tar.xz"
z_DATE_PREFIX="%Y-%m-%d-%H%M"
z_SEPARATOR="-"
now_FORMAT="%Y-%m-%d-%H%M"
now_FORMAT_s="%Y-%m-%d-%H%M%S"

# a cool "cd" version that works also for files (go to file's dir)
# and also accept -n option to go back of n steo '..', 
#
# examples:
# $ cd
# $ mkdir tmp
# $ touch tmp/example.txt
# $ cd tmp/example.txt
# ~/tmp$ mkdir -p level2/level3
# ~/tmp$ cd level2/level3
# ~/tmp/level2/level3$ cd -3
# go back step 3: ../../../
# $
#
#
function cd() { 
    local d="$1" ; 
    local n=
    local i=
    local str=
    if [[ "$d" =~  ^-([0-9]+) ]]; then
   	n="${d:1}"
	for i in $(seq 1 "$n"); do
   	    str+="../"
   	done
	echo go back step $n: $str
   	builtin cd "$str"
    else
	test -z "$d" && d="$HOME"; 
	if [ -f "$d" ]; then 
	    d="$(dirname "$d")";
	      builtin cd "$d"
	else
	    builtin cd "$@"
	fi
	
    fi 
}

function now() {
    local FORMAT=$now_FORMAT
    if [[ $1 == '-h' || $1 == '--help' ]]; then
	cat <<- 'EOF'
 Print date(1) information 

 now     :  with no argument prints date using $now_FORMAT environment
 now -s  :  with -s option prints date using $now_FORMAT_s environment
 now -h | -help  : print this help          

 Current values are:
EOF
	echo " now_FORMAT=$now_FORMAT"
	echo " now_FORMAT_s=$now_FORMAT_s"
	return 0
    fi
    if [ "$1" == '-s' ]; then
	FORMAT=$now_FORMAT_s
    fi
    date +$FORMAT
}

declare -A __h_ids

function t() {
    N="$1"
    test -z "$N" && N=10
    if [[ $N == '-h' || $N == '--help' || ! $N =~ ^([0-9]+) ]]; then
	cat <<- 'EOF'
  Fast ls of last "used" files in $t_DIR. 
  Use it as temporary working directory. 

     t <n> [<id1> [<id2> ...]] [+] [-] [-0]
     t -h | --help

     <n>       : is with no sign show last files in $t_DIR like 'ls -l' style
                 default is 10. example: "t 6" show last 6 files.
     <id1..>   : if given filter only some of the ids (from 1 to <n>)
                 example: "t 5 2 4" only show file #2 and #4 into the list of
                 last 5 files.
     -         : if given show output in 'ls -1rt' style; this is usefull
                 to be used in conjunction with z command, for example:
                 "t 5 - | z" compress last 5 files
     +         : if given show output in 'ls -1rt' style with $t_DIR prefix
     -0        : optional parameter use record separator null character
                 instead of \n. Suitable to be used in conjuntion with 
                 xargs -0 or to fix space issue and quotations. 
                 ignored on "no sign" mode. 
                 example: "t 4 + -0 | xargs -0 rm -v"
     -h,--help : show this help and exit

     Setting t_DIR=$HOME is strongly suggested.
EOF
	echo "     current t_DIR environment is: $t_DIR"
	return 0
    fi
    local type=x
    local ids=
    local CR='\n'
    local lscmd="ls -lrt";
    shift # first param
    local seq1N=
    seq1N="$(seq 1 $N)"
    for i in $seq1N; do
	__h_ids["$i"]=""
    done
    local flag=0
    while [ $# -ge 1 ]; do
	case "$1" in
	    '-')
		type=n
		lscmd="ls -1rt"
		;;
	    '+')
		type=p
		lscmd="ls -1rt"		
		;;
	    '-0')
		CR='\0'
		;;
	    *)
		if [[ $1 =~ [0-9]+ ]]; then
		    __h_ids["$1"]="$1"
		    flag=1  
		fi
		;;
	esac
	shift
    done
    test $flag == 0 && for i in $seq1N; do
	__h_ids["$i"]="$i"
    done
	    
    case "$type" in
	    p)
		${lscmd} --group-directories-first --hide='*~' "$t_DIR" | tail -n "$N" | (let n=$N; while read F; do test "${__h_ids[$n]}" == "$n" && echo -ne "$t_DIR/$F"$CR; let n+=-1; done)
		;;
	    n)
		${lscmd} --group-directories-first --hide='*~' "$t_DIR" | tail -n "$N" | (let n=$N; while read F; do test "${__h_ids[$n]}" == "$n" && echo -ne "$F"$CR; let n+=-1; done) 
		;;
	    *)
		${lscmd} --group-directories-first --hide='*~' "$t_DIR" | tail -n "$N" | (let n=$N; while read F; do test "${__h_ids[$n]}" == "$n" && printf "%2d|$F\n" $n; let n+=-1; done)
		;;
    esac

    return 0
}



function z() {
    local TAG=""
    local NOW=$(date +$z_DATE_PREFIX)
    local FORMAT=
    local M0=
    local POSTFIX=
    function z_which() {
	local cmd="$1"
	which $cmd > /dev/null || if echo "no '$cmd' command found"; then
	    return 1 ;
	fi 
    }
    if [[ $1 == '-h' || $1 == '--help' || $# -gt 3 ]]; then
	cat <<- 'EOF'
  Read list of files from stdin and compress using various compress format.
  Operate on the directory stored in t_DIR enviromnet.
  Both single or multiple file storage format are supported. 
  It is intended to be used in conjunction with 't' command.

     z [FORMAT] [POSTFIX] [-0]
     z -h | --help

  compressed generated format depends on format specified and will be stored
  in t_DIR too with a name prefixed of $t_DATE_PREFIX and postfix 
  given in POSTFIX.

     FORMAT    : choosed output compressed format. Following are supported:
     	         multiple mode: tar,tgz,tar.gz,tar.bz2,tar.xz,7z,zip
                 single mode  : gz,bz2,xz
     POSTFIX   : the postfixed string of the generated compressed file name
                 (ignored in single mode). Extention depends on FORMAT.
     -0        : optional parameter use record separator null character
                 instead of \n. Suitable to be used in conjuntion with 
                 xargs -0 or to fix space issue and quotations. 
                 ignored on "no sign" mode. 
                 example: "t 4 + -0 | xargs -0 rm -v"
     (parameters above can be given in any order)
     -h,--help : show this help and exit

     Setting t_DIR=$HOME is strongly suggested.
EOF
	echo "     current t_DIR environment is: $t_DIR"
	echo "     current t_DATE_FORMAT is    : $t_DATE_FORMAT"
	return 1
    fi    
    while [ $# -ge 1 ]; do
	case "$1" in
	    tar|tgz|tar.gz|tar.bz2|tar.xz|7z|zip|gz|bz2|xz)
		test -n "$FORMAT" && echo "FORMAT have been specified more times" >&2 && return 1
		FORMAT="$1"
		# echo "Using format: $FORMAT " >&2
		;;
	    '-0')
		test -n "$M0" && echo "-0 option have been specified more times" >&2 && return 1
		M0="$1"
		# echo "Using special: -0" >&2
		;;
	    *)
		test -n "$POSTFIX" && echo "POSTFIX option have been specified more times" >&2 && return 1
		POSTFIX="$1"
		# echo "Using PREFIX: $PREFIX" >&2
		;;
	esac
	shift
    done
    test -z "$FORMAT" && FORMAT="$z_DEFAULT_FORMAT"
    local xargsopt="xargs $M0"
    local T=
    test -z "$POSTFIX" && T="${NOW}.${FORMAT}" || T="${NOW}${z_SEPARATOR}${POSTFIX}.${FORMAT}"
    case "$FORMAT" in
	tar)
	    z_which tar || return 2	    
	    (cd $t_DIR && tar fcv "$T" -T -)
	    echo "$T" >&2
	    ;;
	tar.xz|txz)
	    z_which tar || return 2
	    z_which xz || return 2
	    (cd $t_DIR && tar cv -T - | xz -9 > ".$T" && mv -v ".$T" "$T")
	    ;;
	tar.gz|tgz)
	    z_which tar || return 2
	    z_which gzip || return 2
	    (cd $t_DIR && tar cv -T - | gzip -c9 > ".$T" && mv -v ".$T" "$T")
	    ;;
	tar.bz2)
	    z_which tar || return 2
	    z_which bzip2 || return 2
	    (cd $t_DIR && tar cv -T - | bzip2 -c9 > ".$T" && mv -v ".$T" "$T")
	    ;;
	7z)
	    z_which 7z || return 2
	    (cd $t_DIR && cat | tee -a /dev/stderr | $xargsopt 7z a -bd $T)
	    ;;
	zip)
	    z_which zip || return 2
	    (cd $t_DIR && cat | tee -a /dev/stderr | $xargsopt zip -v9 $T)
	    ;;
	gz)
	    z_which bzip2 || return 2
	    (cd $t_DIR && cat | tee -a /dev/stderr | $xargsopt -L 1 gzip -v9)
	    ;;
	xz)
	    z_which xz || return 2	    
	    (cd $t_DIR && cat | tee -a /dev/stderr | $xargsopt -L 1 xz -v9)
	    ;;
	bz2)
	    z_which bzip2 || return 2	    
	    (cd $t_DIR && cat | tee -a /dev/stderr | $xargsopt -L 1 bzip2 -v9)
	    ;;
	*)
	    echo "unknown format: $FORMAT"
	    return 2
	    ;;       
    esac
    return $?
}

