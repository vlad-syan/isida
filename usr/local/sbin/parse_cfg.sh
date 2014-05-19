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
echo `date +%F\ %T`" PARSE: parse_cfg.sh with PID $$ on ip $1 started" >> $log
unknown=0
parser=`grep $model $conf | awk '{print $3}'`

if [ -z "$parser" ]
    then
    unknown=1
fi

#case $model in
#	171.10.64.1)	/usr/local/sbin/parse_cfg_3526.sh $1;;
#	171.10.63.6)	/usr/local/sbin/parse_cfg_3028.sh $1;;
#	171.10.105.1)	/usr/local/sbin/parse_cfg_3528.sh $1;;
#	171.10.116.2)	/usr/local/sbin/parse_cfg_1228ME.sh $1;;
#	171.10.113.1.1)	/usr/local/sbin/parse_cfg_3200A1.sh $1;;
#	171.10.113.1.2)	/usr/local/sbin/parse_cfg_3200A1.sh $1;;
#	171.10.113.1.3)	/usr/local/sbin/parse_cfg_3200A1.sh $1;;
#	171.10.113.1.4)	/usr/local/sbin/parse_cfg_3200A1.sh $1;;
#	171.10.113.1.5)	/usr/local/sbin/parse_cfg_3200A1.sh $1;;
#	171.10.113.6.1)	/usr/local/sbin/parse_cfg_3200C1.sh $1;;
#	*)	unknown=1;;
#esac

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
		/usr/local/sbin/checker.sh $path/dry_$1 >> $check_log
	fi

    fi

    else
    echo `date +%F\ %T` ' PARSE ['$$']:'" unknown device with model $model" >> $log
fi
