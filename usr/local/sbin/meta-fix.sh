#!/bin/bash

if [ -z "$1" ]
	then
	exit 0
fi

conf='/etc/isida/model.conf'
log='/var/log/isida.log'
ip=$3
model=$4
expect_string=`grep $model $conf | awk '{print $8}'
expect_cmd=`grep $expect_string $conf | awk -F= '{print $2}' | sed -e s/%ip/$ip/`
fix_ex='/tmp/isida_'$ip'_fix.ex'
fix='/tmp/isida_'$ip'_fix'
str=''
count=1

for i in $@
	do

	if [ $count -gt 4 ]
		then
		str=$str' '$i
	fi

	count=$((count +1))
done

fix_cmd=`grep $model $conf | awk '{print $9}'`
echo `date +%F\ %T`' FIX ['$$']:' $ip get to meta-fix.sh with \"$str\", model $model >> $log
$fix_cmd $ip $str > $fix

if [ -s $fix ]
	then
	$expect_cmd $fix > $fix_ex
	echo `date +%F\ %T`' FIX ['$$']: done, expect script created' >> $log
fi

echo `date +%F\ %T`' FIX ['$$']: done, nothing to fix' >> $log
