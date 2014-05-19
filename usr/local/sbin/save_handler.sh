#!/bin/bash

if [ -z "$1" ]
    then
    exit 0
fi

conf='/etc/isida/model.conf'
log='/var/log/isida.log'
echo `date +%F\ %T`" HANDLER: handler started with PID $$" >> $log
ip=$1
echo `date +%F\ %T` 'HANDLER ['$$']:' $ip "read from spooler" >> $log

if [ "`/usr/local/sbin/ping_equip.sh $ip`" = "0" ]
	then
	echo `date +%F\ %T` 'HANDLER ['$$']:' $ip offline, added to spool again';' handler ends >> $log
	touch /var/spool/isida/$ip
	exit 0
fi

model=`/usr/local/sbin/get_model.sh $ip`
OID=`grep $model $conf | grep -v '#' | awk '{print $5}'`
value=`grep $model $conf | grep -v '#' |awk '{print $6}'`
#skip_cmd=`grep "skip_cmd" $conf | grep -v '#' |awk -F= '{print $2}'`
#skip_value=`grep "skip_value" $conf | grep -v '#' |awk -F= '{print $2}'`
#
#if [ "`$skip_cmd`" = "$skip_value" ]
#	then
#	echo `date +%F\ %T` 'HANDLER ['$$']:' $ip skipped >> $log
#	exit 0
#fi

ready=$value

while [ $ready -eq $value ]
    do
    sleep 1
    ready=`snmpget -Ovq -v2c -c dlread $ip $OID`
done


/usr/local/sbin/backup_config_L2.sh $ip $model
echo `date +%F\ %T` 'HANDLER ['$$']:' with $ip ends >> $log

exit 0

