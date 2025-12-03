# this is a nice content to be inserted into ~/.bashrc file:
# you can also put this line at the end of ~/.bashrc:
# source /my-pegaso-root-dir/lib/bash/bashrc.lib.sh

# usefull to store a command in history without execute:
alias s='history -s '
t_DIR=$HOME
z_DEFAULT_FORMAT="tar.xz"
z_DATE_PREFIX="%Y-%m-%d-%H%M"
z_SEPARATOR="-"
cd_NFIFO=20
cd_FLOCKCMD="flock -x -w 5 200"
cd_FLOCKPATH=/var/lock/.pegaso.cd.cache
new_chr="_"
now_FORMAT="%Y-%m-%d-%H%M"
now_FORMAT_s="%Y-%m-%d-%H%M%S"
t_PEGASO_CONF_DIR=$HOME/.pegaso
pwd_SUBST="__"
pwd_cmd="$(which pwd)"



function _extract_by_slash() {
    local input_string="$1"
    local n="$2"
    
    if (( n == 0 )); then
        # N è zero, ritorna la stringa intera
        echo "$input_string"
        return
    elif (( n > 0 )); then
	# count from left to right
        echo "$input_string" | cut -d'/' -f$((n + 1))-
    else
	# count from right to left
        local occurrences=$(( -n ))
        echo "$input_string" | rev | cut -d'/' -f$((occurrences + 1))- | rev
    fi
}



function _parse_command_for_pwd() {
    # dovrebber parserizzare meglio pwd
    # fatto con chatgpt
    #
    local subst_string=""
    local n_value=""
    local option_s=false
    local option_r=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s)
                option_s=true
                # Se c'è un secondo argomento e non è un'opzione, trattalo come subst-string
                if [[ -n "$2" && "$2" != -* ]]; then
                    subst_string="$2"
                    shift # Avanza per saltare anche subst-string
                fi
                ;;
            -r)
                option_r=true
                # Controlla se c'è un numero intero (con o senza segno) come argomento per -r
                if [[ -n "$2" && "$2" =~ ^-?[0-9]+$ ]]; then
                    n_value="$2"
                    shift # Avanza per saltare il numero
                else
                    echo "Errore: -r richiede un numero intero come argomento" >&2
                    return 1
                fi
                ;;
            *)
                echo "Errore: opzione non riconosciuta $1" >&2
                return 1
                ;;
        esac
        shift
    done

    # Mostra i valori delle variabili parsate (per debug)
    echo "Substitute string: ${subst_string:-Nessuna}"
    echo "N value: ${n_value:-Nessuno}"
    echo "Option -s set: $option_s"
    echo "Option -r set: $option_r"
}


# pwd extention:
function pwd() {
	local subst="$pwd_SUBST"
	local v=
	local n=
	local opt_x=0
	local opt_s=
	local opt_r=
	local opt_s_v="$pwd_SUBST"
	local opt_r_v=
	if [[ $1 == '-h' || $1 == '--help' ]]; then
		cat<<EOF
PEGASO pwd(1) extention:
	pwd [-s [subst-string [-r <N>|-<N>]]]
        pwd [-h | --help]
        pwd ....

        execute pwd(1) command; with -s substitute '/' with subst-string (default is $pwd_SUBST)

current pwd_SUBST=$pwd_SUBST

EOF
	fi
	
	if [[ $1 == '-s' ]]; then
		if [[ -n $2 ]]; then
			subst="$2"
			shift
		fi
		v="$($pwd_cmd)"
		if [[ $2 == '-r' ]]; then
			if [[ $3 =~  ^-?[0-9]+$ ]]; then 
				n="$3"
				shift
				v="$(_extract_by_slash "$v" $n)"
			else
				echo "error -r argument shall be a signed integer number" >&2 
				return 1
			fi
		else
			v="$($pwd_cmd)"
		fi
		echo "${v//\//$subst}"
		
	else
		$pwd_cmd $*
	fi
}


function win2posix() {
	local path="$1"
	echo "$path" | sed 's/\\/\//g' | sed 's/://'
}

function fifo() {
    local n="$1"
    local f="$2"
    if [[ $n == '-h' || $n == '--help' || -z $n || $# != 2 ]]; then
	cat <<EOF
read from stdin and add content to <filename>; limit total lines of <filename> to be last <n> inserted.

  fifo <n> <filename>

if <filename> will be created if does not exist.
EOF
	return 0
    fi
    if [[ ! -f $f ]]; then
	cat > "$f"
    else
	cat >> "$f"
    fi
    local t=
    t=$(cat "$f" | wc -l)
    if [[ $t -gt $n ]]; then
	let diff="$t-$n"
	# echo "diff: $diff" >&2
	sed -i -e "1,${diff} d" $f
    fi
}

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
    local biret= # built in return
    local toposix=
    if [[ $1 == '-h' || $1 == '--help' ]]; then
	cat <<EOF
you are using che 'PEGASO' version of 'cd', a wrapper of the build-in cd that improve usage to fast change level and fast go to last used changed dir in the cache.

  cd -NLEVEL
  cd %[NFIFO]
  cd <built-in-options>
  cd ? | :?

  NLEVEL number of up level (..) to change go.
  NFIFO  number of line in saved cache to change to. use "cd %" to show the cache.
example:


  cd -3
     go up one 3 level like  cd ../../..
  cd %
     show the full cash
  cd %18
     change directory to the 18th cached directory.
  cd <build-in params...> 
     execute build-in bash; if fails, do "fast" cd, see above.
  cd ? | :?
     show available directories for "fast" cd. sometime '?' do now work due
     to shell substitution, so alias ':?' can be used too.

if option above are not recognized, the build-in bash cd command is called
passing all left parameter. You can use 'buildin cd' command to force use
of the original bash 'cd' command in your environment.

Moreover: if the built-in cd command also fails, the parameter is 
interpreted to be a <name> that is expected to be a symbolic link
located into \$t_PEGASO_CONF_DIR/cd/<name> . If this symlink exists,
the directory is changed to the one linked to. You can so easy install
"fast" cd command, that is also independent of the current location, 
by adding a simple symlink into \$t_PEGASO_CONF_DIR/cd/ directory.

maximum number of cache is controlled by the environent 'cd_NFIFO',
EOF
	echo "current value is: $cd_NFIFO"
	echo "current t_PEGASO_CONF_DIR=$t_PEGASO_CONF_DIR"
	echo "builtin cd help is:"
	builtin cd -h
	return 0
    fi
    if [[ $d == '?' || $d == ':?' ]]; then
	ls $t_PEGASO_CONF_DIR/cd
	return $?
    fi
    if [[ $d =~ %(([0-9]*)?) ]]; then             
	    if [[ -z ${d:1} ]]; then	    
		cat $HOME/.cd.saved | perl -ne '$i++; print sprintf("%2d $_",$i);'
	    else
		d=$(head -n ${d:1} $HOME/.cd.saved | tail -n 1)
		# manage write lock on file:
		builtin cd "$d" && ( $cd_FLOCKCMD; pwd | fifo $cd_NFIFO $HOME/.cd.saved) 200>$cd_FLOCKPATH 
	fi
	return 0
    fi
    if [[ "$d" =~  ^-([0-9]+) ]]; then
   	n="${d:1}"
	for i in $(seq 1 "$n"); do
   	    str+="../"
   	done
	echo go back step $n: $str
    else
	test -z "$d" && d="$HOME"; 
	if [ -d "$d" ]; then 
	    str="$@"    
	else
	    if [ -f "$d" ]; then
		    d="$(dirname "$d")";
		    str="$d"
	    else
	    	str="$d"
	    fi
	fi
    fi 
    # echo "trace: $str"
    if test -n "$str"; then
    	builtin cd "$str"
    else
    	builtin cd
    fi
    biret=$?
    toposix="$(win2posix "$str")"
    test $biret != 0 -a "$str" != "$toposix" && builtin cd "$toposix" && biret=$?
    if [ $biret != 0  ] ; then
    	str="$(readlink -f "$t_PEGASO_CONF_DIR/cd/$str")"
    	echo fast cd to: $str
    	builtin cd "$str"
    	return $?
    fi
    return $biret
}
function mkcd() { 
    # a combination of "mkdir -p" + "cd" shell command
    local d="$1" ; 
    mkdir -p "$d" && builtin cd "$d"
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


function prv_rmspaces() {
	local f="$1"
	local B="$(basename "$F")"
    	local D="$(dirname "$F")"
    	local NB=$(echo "$B" | tr " " "$new_chr")
    	(cd "$D" && mv "$B" "$NB")
    	return $?
}

function rmspaces() {
     if [[ "$1" == '-h' || "$1" == '--help' ]]; then
	cat <<- 'EOF'	
 remove spaces from the file name or directory with a character defined in 'new_chr' environment.
 default is underscore ("_").
 directory path is never changed, only filename.
 with no parameters, standard input is read as the list of file paths, one for each line.
 
 rmspace [[<filepath1> [<filepath2> ]]...
 
 example:
 
 # rmspace "my file with space.txt" "my file with more      spaces.txt" 
   rename file to be "my_file_with_spaces.txt" and "my_file_with_more_spaces.txt" rispectively.
 # new_chr='-' rmspace "my file with space.txt" 
   rename the file "my file with space.txt" with  "my-file-with-space.txt" 
 # ls -1 myprefix* | xargs -L 1 | new_chr='-' rmspaces
   remove spaces to all files starting with "myprefix" using "-" replacement
 
EOF
	echo " current 'new_chr' is: '$new_chr'"
	return 0
    fi
    local F=
    local B=
    local D=
    local NB=
    if [ $# == 0 ]; then
    	while read F; do
    		prv_rmspaces "$F"
    	done
    	return 0
    fi
    while [ $# -ge 1 ]; do
    	F="$1"
    	shift
    	if [ -e "$F" ]; then
    		prv_rmspaces "$F"
    	else
    		echo "$F not a file or directory"
    	fi
    done
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

alias tlast='t 1 +'


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
  in t_DIR too with a name prefixed of $z_DATE_PREFIX and postfix 
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
                 example: "t 4 1 2 3 - -0 | z tar.gz -0"
     (parameters above can be given in any order)
     -h,--help : show this help and exit

     Setting t_DIR=$HOME is strongly suggested.
EOF
	echo "     current t_DIR environment is: $t_DIR"
	echo "     current z_DATE_PREFIX is: $z_DATE_PREFIX"
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


function save() {
    local TAG=""
    local NOW=$(date +$z_DATE_PREFIX)
    local FORMAT=
    local M0=
    local POSTFIX=
    if [[ $1 == '-h' || $1 == '--help' || $# -gt 3 ]]; then
	cat <<- 'EOF'
  Save the standard input in file in t_DIR directory with a 
  standard or a given name.
 
  <params> are the same of t

     save <params...>
     save -h | --help

     if filename is not given , use "saved-<z_DATE_PREFIX>.tmp' template
     -h,--help : show this help and exit

     Setting t_DIR=$HOME is strongly suggested.
EOF
	echo "     current t_DIR environment is: $t_DIR"
	return 1
    fi
    local FILENAME=
    local ret=0
    FILENAME="$1"
    test -z "$FILENAME" && FILENAME="${t_DIR}/saved-${NOW}.tmp"
    cat > $FILENAME
    ret=$?
    echo >&2 "written $FILENAME"
    return $ret
}

function saved() {
    if [[ $1 == '-h' || $1 == '--help' ]]; then
	cat <<- 'EOF'
  'cat' print to stdout of the <id> file in the stack list, as used in t command (see). 
   Default id is 1. Used in conjuntion with save command. 

     saved [<id>]
     saved -h | --help

     -h,--help : show this help and exit

     Setting t_DIR=$HOME is strongly suggested.

EOF
	echo "     current t_DIR environment is: $t_DIR"
	return 1
    fi
    if [ $# == 0 ]; then
	t 1 1 + -0 | xargs -L 1 -0 cat
    else
	t $* + -0 | xargs -L 1 -0 cat
    fi
    ret=$?
    return $ret
}

function te() {
    if [[ $1 == '-h' || $1 == '--help' ]]; then
	cat <<- 'EOF'
  execute an arbitraty command from the t_DIR directory

     te <command> [param1 [param2 ...]]
     te -h | --help

     -h,--help : show this help and exit

     Setting t_DIR=$HOME is strongly suggested.
EOF
	echo "     current t_DIR environment is: $t_DIR"
	return 1
    fi    
    (cd $t_DIR &&
	 $* )
    ret=$?
    return $ret
}


alias rslash='pegaso-rslash'

