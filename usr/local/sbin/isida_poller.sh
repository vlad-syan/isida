#!/bin/bash

spool='/var/spool/isida'
log='/var/log/isida.log'
echo `date +%F\ %T`' POLLER ['$$']: started' >> $log
list=`ls -1 $spool`

for i in $list
	do
	rm $spool/$i
done


for i in $list
	do
	echo `date +%F\ %T`' POLLER ['$$']: '"processing $i" >> $log
	/usr/local/sbin/save_handler.sh $i &
done

echo `date +%F\ %T`' POLLER ['$$']: ends' >> $log

