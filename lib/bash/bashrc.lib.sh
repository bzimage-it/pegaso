# this is a nice content to be inserted into ~/.bashrc file:
# you can also put this line at the end of ~/.bashrc:
# source /my-pegaso-root-dir/lib/bash/bashrc.lib.sh

# usefull to store a command in history without execute:
alias s='history -s '

# a cool "cd" version that works also for files (go to file's dir)
cd(){ local d="$@" ; test -z "$d" && d="$HOME"; if [ -f "$d" ]; then d=$(dirname "$d"); fi; builtin cd "$d"; }


