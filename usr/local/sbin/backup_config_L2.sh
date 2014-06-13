#!/bin/bash
ip=$1
model=$2
conf='/etc/isida/model.conf'
general_conf='/etc/isida/isida.conf'
path=`grep "tftp_root" $general_conf | awk -F= '{print $2}'`
get_uplink=`grep 'uplink' $general_conf | cut -d= -f2 | sed -e s/%ip/$ip/`
dry=$path/dry/$ip
log='/var/log/isida.log'
temp_check='/tmp/'`date +%s%N`'.check'
dummy_ex="/tmp/get_cfg_$ip.ex"
dummy_cmd="/tmp/"`date +%s%N`
exclude_ip="/etc/isida/exclude_ip"
exclude_model="/etc/isida/exclude_model"
echo `date +%F\ %T`" BACKUP: started backup_config_L2.sh with PID $$ on $ip" >> $log

if [ "`/usr/local/sbin/ping_equip.sh $ip`" = "0" ]
	then
	echo `date +%F\ %T` 'BACKUP ['$$']:'" $ip is offline" >> $log
	exit 0
fi

uplink=`$get_uplink`
command_id=`grep $model $conf | awk '{print $7}'`
command=`grep "$command_id=" $conf | awk -F= '{print $2}' | sed -e s/%ip/$ip/`
echo "$command" > $dummy_cmd
expect_id=`grep $model $conf | awk '{print $8}'`
expect_cmd=`grep "$expect_id=" $conf | awk -F= '{print $2}' | sed -e s/%ip/$ip/`

echo $expect_cmd

if [ ! -d "$path/old/`date +%F`" ]
	then
	mkdir $path/old/`date +%F`
fi

mv $path/$ip $path/old/`date +%F`/`date +%T`_$ip
count=0
$expect_cmd $dummy_cmd > $dummy_ex

function get_cfg() {
count=$((count + 1))

if [ $count -gt 10 ]
	then
	echo `date +%F\ %T` 'BACKUP ['$$']:'" $ip cfg download FAILED after $count attempts" >> $log
	return 2
fi

echo `date +%F\ %T` 'BACKUP ['$$']:'" $ip cfg download started ($count)" >> $log
time /usr/bin/expect -f $dummy_ex


if [ ! -s "$path/$ip" ]
	then
	return 1
else
	return 0
fi

}

result=1

while [ $result -eq 1 ]
	do
	get_cfg
	result=$?
done


if [ $result -eq 0 ]
	then
	echo `date +%F\ %T` 'BACKUP ['$$']:'" $ip cfg downloaded after $count attempt(s)" >> $log

	if [ `grep -cw $model $exclude_model` -eq 0 ] && [ `grep -cw $ip $exclude_ip` -eq 0 ]
		then
		/usr/local/sbin/meta-parse.sh $ip > $dry
		echo `date +%F\ %T` 'BACKUP ['$$']:'" forwarded to checker" >> $log
		/usr/local/sbin/checker.sh $dry $uplink >> $temp_check

		if [ $? -eq 0 ]
			then
			cat $temp_check >> /var/log/checker.log
			/usr/local/sbin/meta-fix.sh `cat $temp_check`
			rm -f $temp_check
		elif [ $? -eq 1 ]
			then
			echo `date +%F\ %T` 'BACKUP ['$$']:'" something wrong with dry config" >> $log
		else
			echo `date +%F\ %T` 'BACKUP ['$$']:'" something wrong with checker" >> $log
		fi

	    else
		echo `date +%F\ %T` 'BACKUP ['$$']:'" $ip in exclude-list" >> $log
	fi
fi

echo `date +%F\ %T` 'BACKUP ['$$']:'" ends" >> $log
rm -f $dummy_ex $dummy_cmd

