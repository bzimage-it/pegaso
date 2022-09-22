# alias expr="python3 c-expr.py"

function _args() {
    for F in $*; do
	echo "*        | $F"
    done
    for F in "$*"; do
	echo "quoted * | $F"
    done
    for F in $@; do
	echo "@        | $F"
    done    
    for F in "$@"; do
	echo "quoted @ | $F"
    done    
}

function c-expr() {
    python3 c-expr.py "$@"
}

function c-compare() {
    local actual_value="$1"
    local expected_value="$2"
    if [[ -z $expected_value ]]; then
	cat <<EOF
sintax: c-compare <double-value1> <double-value2>

compare 2 double value in particular last bit of mantissa for ULP analisys

examples: c-compare 2.555555555 2.55555556
          c-compare M_PI  "(M_PI+10E-20)"
EOF
	
	return 1
    fi
    c-expr 'MSG("VALUES");D(av,'"$1);D(ev,$2"');DUMP(av);DUMP(ev);COMPARE(av,ev);'
}

function c-nextafter() {
    local from="$1"
    local spec="$2"
    local to=
    if [[ -z $from ]]; then
	cat <<EOF
sintax: c-nextafter <double-value-from> [+value | -value | <double-value-to> ]

execute nextafter() c++ math.h function on the <double-value-from> with 
value of "to" based on the second parameter:
* +value , pass a value of to "<double-value-from>+value"
* -value , pass a value of to "<double-value-from>-value"
*  <double-value-to>, pass it as "to" directly

second parameter default is "<double-value-from>+1".

valid symbols valid in math library can be used too.

examples:
	c-nextafter 3.55555 +1
	c-nextafter 3.55555 -1
	c-nextafter M_PI_4 
EOF
	return 1
    fi
    if [[ $spec =~ ^\- || $spec =~ ^\+ ]]; then
	to="x.value$spec";
    elif [[ -z $spec ]]; then
	to="x.value+1";
    else
	to="$spec"
    fi
    echo "spec: $spec - from: $from - to: $to"
    c-expr "D(x,$from);D(r,nextafter(x.value,$to)); DUMP(x); DUMP(r);" 
}


