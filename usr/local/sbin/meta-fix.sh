#!/bin/bash

if [ -z $1 ]
	then
	exit 0
fi

conf='/etc/isida/model.conf'
log='/var/log/isida.log'
ip=$3
model=$4
str=`echo $@ | sed -e s/$1// -e s/$2// -e s/$3// -e s/$4//`
fix_cmd=`grep $model $conf | awk '{print $9}'`
echo `date +%F\ %T`' FIX ['$$']:' $ip get to meta-fix.sh with \"$str\", model $model
echo $fix_cmd $ip $str
echo `date +%F\ %T`' FIX ['$$']: done'
