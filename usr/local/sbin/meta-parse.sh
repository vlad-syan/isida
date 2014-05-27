#!/bin/bash

if [ -z $1 ]
	then
	exit 0
fi
path=`grep 'tftp_root' /etc/isida/isida.conf | cut -d '=' -f2`
model=`/usr/local/sbin/get_model.sh $1`
conf='/etc/isida/model.conf'
log='/var/log/isida.log'
check_log='/var/log/checker.log'
echo `date +%F\ %T`" PARSE: meta-parse.sh with PID $$ on ip $1 started" >> $log
unknown=0
parser=`grep $model $conf | awk '{print $3}'`
tmp='/tmp/'`date +%N`'.chk'

if [ -z "$parser" ]
    then
    unknown=1
fi

if [ $unknown -eq 0 ]
    then

    if [ -z $2 ]
	then
	$parser $1
	echo `date +%F\ %T`' PARSE ['$$']:'" $1 cfg parsed" >> $log
	else

	if [ "$2" = "forward" ]
		then
		$parser $1
		echo `date +%F\ %T` ' PARSE ['$$']:'" parsed cfg from $1, forwarded to checker" >> $log
		/usr/local/sbin/checker.sh $path/dry_$1 >> $tmp
		cat $tmp >> $check_log
		fix_args=`cat $tmp`
		/usr/local/sbin/meta-fix.sh $fix_args 
	fi

    fi

    else
    echo `date +%F\ %T` ' PARSE ['$$']:'" unknown device with model $model" >> $log
fi
