

function test_pre() { # crea dei file di test
    local rtest=space2_test
    rm -rf $rtest
    for d in dir1 "dir2 space" "dir3 space"; do
	p="$rtest/$d"
	mkdir -p "$p"
	for f in f1 "f2 a ciao cia o bell a" "f3 a  b cccc hello  wolr d" "a b"; do
	   echo "$f" > "$p/$f"
	done
    done
    find $rtest
}

function test_post() { # eseguita alla fine per verificare, visivamente, se ok
    find space2_test
}

function remove_space() {
	local sub="$1"
	local pathname="$2"
	local base="$(basename "$pathname")"
	local dir="$(dirname "$pathname")"
	#echo "file da processare: $base"
	#echo "dir file: $dir"
	local BASE_WITH_SUB="${base//" "/"$sub"}"
	echo "$dir/$BASE_WITH_SUB"
}

function rename_subst() {
	local sub="$1"
	local pathname="$2"
	
	if [ ${#pathname} = 0 ] ; then
		echo "ERROR: pathname vuoto"
		return 1
	fi
	
	if [ ${#sub} = 0 ] ; then
		echo "ERROR: sub vuoto"
		return 2
	fi
	
	if [ ! -e "$pathname" ] ; then
		echo "'$pathname' : inesistente"
		return 3
	fi
	
	if [ ${#pathname} != 0 -a ${#sub} != 0 -a -e "$pathname" ] ; then
		local base="$(basename "$pathname")"
		local dir="$(dirname "$pathname")"
		local b2="${base//" "/"$sub"}"
		local new_path="$dir/$b2"
		if [ "$base" != "$b2" ]; then
			mv -v "$pathname" "$new_path" && return 0
			return 5
		fi
		return 0
	fi
}

#function remove_space() {

#	local STRING_WITH_WHITESPACE= "$2"
#	local SUBSTITUTE="$1"
#	local LONG_STRING_WITH_SUBSTITUTE= $LONG_STRING_WITH_WHITESPACE | sed -e 's, ,$1,g'
	

#	echo $STRING_WITH_SUBSTITUTE
#}

test_pre

# program body goes here:

# for file in "$@" ; do
# 	echo $file
# done

# remove_space _ "space2_test/dir3 space/f3 a  b cccc hello  wolr d"
# remove_space % "space2_test/dir1/f2 a ciao cia o bell a"


find space2_test -print0 > /tmp/File
cat /tmp/File | xargs -0 -L 1 | while read F; do
	echo -ne "\n--- $F"
	rename_subst _ "$F" || exit 1
done 
# end of program
test_post


