#!/bin/bash

if [ -z $1 ]
	then
	exit 0
fi

ip=$1
rules=$2
trunk=$3
access=$4
port_count=`echo $5 | sed -e s/://`
args=''
count=0
enum_pars=`cat $rules | grep -v '#' | grep '\.x\.' | cut -d. -f1 | uniq`
raw_fix='/tmp/'`date +%sN`'-fix'

for i in $@
	do
	count=$((count + 1))
	
	if [ $count -lt 6 ]
		then
		continue
	fi

	if [ `echo $enum_pars | grep -c $i` -eq 0 ]
		then
		###
	fi

done

#echo $enum_pars
