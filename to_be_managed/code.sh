
# python="python3 -Wdefault::OverflowWarning"

PRIMES=

# PRIMES="9264317	9264329	9264349	9264389	9264391	9264397	9264403	9264407	9264449	9264461"
# PRIMES="9260857	9260861	9260873	9260887	9260893	9260899	9260921	9260939	9260963"

stop=0
for N in $PRIMES; do
    let r="(($N % 4))"
    echo "$N :$r"
    stop=1
done

test $stop == 1 && exit 0

python="python3"

# the lartest pattern is AA999ZZ:
let max="((21*21 * 1000 * 21*21))"

gcc -o check -D"MAX=$max" -DCONTINUE=0 ~/git/pegaso/to_be_managed/occurence_int.c

if [ $# == 0 ]; then
    ALL_PATTERN="AAA999 AA999ZZ AA999888 AA99 AA99ZZ"
else
    ALL_PATTERN="$*"
fi

for PATTERN in $ALL_PATTERN; do

    echo "================== $PATTERN ====================="
    echo max: $max

    $python code.py 2>&1 | head -n 3
    # read -p "PRESS ENTER TO START..." RISP
    ($python code.py $PATTERN | tee $PATTERN.pipe | ./check) 2>&1 | tee $PATTERN.out

    echo "LAST lines of out, real:"
    tail -n 10 $PATTERN.out

    echo "LAST lines of pipe, real:"
    tail -n 10 $PATTERN.pipe

    echo "RE-RUN CHECK only on pipe flow:"
    ./check < $PATTERN.pipe

    ./check < $PATTERN.pipe | grep duplicated | cut -f 2 -d " " | head -n 10 | xargs -I % grep -nH % $PATTERN.pipe $PATTERN.out

    # test -n "$DUP" && grep -nH "$DUP" check.pipe code.out

done
