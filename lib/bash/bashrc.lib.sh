# this is a nice content to be inserted into ~/.bashrc file:
# you can also put this line at the end of ~/.bashrc:
# source /my-pegaso-root-dir/lib/bash/bashrc.lib.sh

# usefull to store a command in history without execute:
alias s='history -s '

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
cd() { 
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


# Fast zip execution of last "used" files in $HOME.
# Use $HOME as as temporary working directory 
# if found use 7z, otherwhice use zip
# Parameters:
#    tag: postfix to the file name. 
#    n  : number of most recent used file to zip.
# with no params show last 10 used files in $HOME

function fz() {
    if [ $# != 2 ];then
	echo "<tag> <n>"
	#    echo $0 "<tag> <file1> <file2>"
 	ls -lrt --hide='*~' $HOME | tail -n 10
	return 0
    fi
    
    TAG="$1"
    N="$2"
    ZIP="zip -9"
    EXT="zip"

    which 7z > /dev/null && ZIP="7z a -bd" && EXT=7z
    
    ( cd "$HOME" &&
	  NOW=$(date +%Y-%m-%d-%H%M)
	  FILES="$(ls -1rt --hide='*~' . | tail -n $N | xargs)" &&
	      echo "putting $FILES into 7z ..." &&
	      T="${NOW}-$TAG.$EXT" &&
	      $ZIP "$T" $FILES &&
	  echo "CREATED $HOME/$T" )
    return $?
}

