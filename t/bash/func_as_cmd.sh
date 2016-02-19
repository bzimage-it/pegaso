#!/bin/bash

tROOT="$(dirname $0)"

tU=$tROOT/../../lib/bash/func_as_cmd.sh || exit 2


tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}


tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}
tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

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

function func1_not_included () {
    echo never called
}

tU=$PEGASO_PARENT_ROOT/lib/bash/utils.lib.sh

function tabort() {
    echo "tabort called: $1"
    exit 10
}

function myexec () {
