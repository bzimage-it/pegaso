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


