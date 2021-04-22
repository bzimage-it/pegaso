#!/bin/bash

tmp=/tmp/endian.$$.c
bin=/tmp/endian.$$

echo 'int main(void) { long one=1; return !(*((char *)(&one))); }' > $tmp  && 
	gcc -o $bin $tmp && 
	if $bin; then 
		echo "Im Little endian"; 
	else 
		echo "Im Big endian" ; 
	fi

rm -f $tmp $bin

