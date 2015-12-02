#!/bin/bash

tROOT="$(dirname $0)"

source $tROOT/../../snippets/bash/header.sh || exit 2

test "$(basename $PEGASO_ROOT)" == snippets || exit 3
test "$(basename $PEGASO_PARENT_ROOT)" == pegaso || exit 4

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh
source $tU  || exit 5

tX=ciccio
tY=pluto
tZ=paperino

t=$(tempfile)

function tabort() {
    echo "tabort called: $1"
    exit 10
}

function myexec () {
    local file=$1
    local expect=$2
    local abort_msg=$3
    cat $file | tee -a /dev/stderr | bash -x
    test $? == $expect || tabort "$abort_msg"    
}

ID=ABRA
cat <<EOF > $t 
   source $tU
   pegaso_assert "aa == ab" "abort $ID"
   exit 0
EOF
myexec $t 1 $ID 

ID=ABRA2
cat <<EOF > $t 
   source $tU
   pegaso_assert "aa == aa" "abort $ID"
   exit 0
EOF
myexec $t 0 $ID 


ID=CADA
cat <<EOF > $t
   source $tU
   X=$tX
   Y=$tY
   Z=$tZ
   pegaso_assert "\$X == ciccio" "abort $ID - 1"   
   pegaso_assert "\$X != pluto"  "abort $ID - 2"
   pegaso_assert "\$X != \$Y"    "abort $ID - 3"
   pegaso_assert "\$X != \$Y -a \$Z != \$Y" "abort $ID - 4"
   exit 0
EOF
myexec $t 0 $ID

ID=EMALE
cat <<EOF > $t
   source $tU
   pegaso_assert_eq 1 1 "abort $ID - 1"
   pegaso_assert_eq ciccio ciccio "abort $ID - 2"  
   exit 0
EOF
myexec $t 0 $ID

ID=EMALE2
cat <<EOF > $t
   source $tU
   pegaso_assert_eq 1 2 "abort $ID - 1"
   exit 0
EOF
myexec $t 1 $ID


ID=DEF1
cat <<EOF > $t
   source $tU
   pegaso_assert_def defined "abort $ID - 1"
   exit 0
EOF
myexec $t 0 $ID

ID=DEF1
cat <<EOF > $t
   source $tU
   undef=
   pegaso_assert_def "\$undef" "abort $ID - 1"
   exit 0
EOF
myexec $t 1 $ID

echo EXIT SUCCESSFULL
exit 0