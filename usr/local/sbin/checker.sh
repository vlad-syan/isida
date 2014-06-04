#!/bin/bash

rules_original='/etc/isida/checker_rules.conf'
rules='/tmp/'`date +%s%N`
conf='/etc/isida/model.conf'
log='/var/log/isida.log'

if [ ! -f $rules_original ]
	then
	echo "No rules file found!"
	exit 1
fi

cfg='/tmp/cfg_'`date +%s%N`

if [ -z $1 ]
	then
	echo "No dry config specified!"
	exit 1
fi

if [ ! -f $1 ]
	then
	echo "No dry config found at $cfg'!'"
	exit 1
fi

ip=`echo $1 | awk -F'/' '{print $NF}'`
cp $1 $cfg
/usr/local/sbin/collapse_ism.sh $1 >> $cfg
trunk=`grep "trunk" $cfg | cut -d '=' -f2`
model=`grep "model" $cfg | cut -d '=' -f2`
fw=`grep "firmware" $cfg | cut -d '=' -f2`
all='1-28'
previous_sum=0
echo `date +%F\ %T` "CHECK: started checker with PID $$ on $1" >> $log

for i in `grep "vlan_name=" $cfg | cut -d '=' -f2`
	do
	sum=0
	ports=`grep "$i.untagged=" $cfg | cut -d '=' -f2 | xargs -l /usr/local/sbin/interval_to_string.sh | xargs -l /usr/local/sbin/string_to_bitmask.sh`

	for j in $ports
		do
		sum=$((sum + j))
	done

	if [ $sum -gt $previous_sum ]
		then
		access_vlan=$i
		previous_sum=$sum
	fi

done

access=`grep "$access_vlan.untagged=" $cfg | cut -d '=' -f2`
port_count=`grep $model $conf | awk '{print $4}'`
echo -n `date +%F\ %T`" $ip $model $rules $trunk $access $port_count: "

if [ -z "$port_count" ]
	then
	exit 0
fi

not_trunk=`/usr/local/sbin/invert_string_interval.sh $trunk $port_count`
not_access=`/usr/local/sbin/invert_string_interval.sh $access $port_count`
all="1-$port_count"

cat $rules_original | grep -v '#' | grep -v '\$' | sed -e s/=trunk/=$trunk/g -e s/=not_trunk/=$not_trunk/g -e s/=all_ports/=$all/g \
	-e s/=access/=$access/g -e s/=not_access/=$not_access/g > $rules

for i in `grep '\$' $cfg | grep -v '#'`
	do
	condition=`echo $i | cut -d '=' -f1 | sed -e 's/\$//' -e 's/\!//'`
	condition_model=`echo $condition | cut -d '^' -f1 | awk -F'@' '{print $1}'`
	condition_fw=`echo $condition | cut -d '^' -f1 | awk -F'@' '{print $2}'`
	condition_cfg=`echo $i | cut -d '^' -f2`
	negative=`echo $i | grep -c '!'`
	model_match=0
	fw_match=0

	if [ -z "$condition_fw" ]
		then
		fw_match=1
		else

			if [ `echo $firmware | grep -c $condition_fw` -eq 1 ]
				then
				fw_match=1
			fi

	fi

	if [ "$condition_model" = "$model" ]
		then
		model_match=1
	fi

	match=$((fw_match + model_match)) # 2 - if full match

	if [ $negative -eq 0 ] && [ $match -eq 2 ]
		then
		echo $condition_cfg | sed -e s/=trunk/=$trunk/g -e s/=not_trunk/=$not_trunk/g \
			-e s/=all/=$all/g -e s/=not_access/=$not_access/g -e s/=access/=$access/g >> $rules
	fi

	if [ $negative -eq 1 ] && [ $match -lt 2 ]
		then
                echo $condition_cfg | sed -e s/=trunk/=$trunk/g -e s/=not_trunk/=$not_trunk/g \
			-e s/=all/=$all/g -e s/=access/=$access/g -e s/=not_access/=$not_access/g >> $rules
	fi

done

function check_key {

	if [ -z $2 ]
		then
		k=$1
	else
		k=`echo $1 | sed -e s/.$2./.x./`
	fi

	correct_value=`grep $k $rules | cut -d '=' -f2`
	value=`grep $1 $cfg | cut -d '=' -f2`

	if [ `echo $correct_value | grep -c '::'` -eq 0 ]
		then

		if [ "$value" = "$correct_value" ]
			then
			result=OK
			return 0
		else

			if [ -z "$value" ]
				then
				value='<empty>'
			fi

			result="$value"
			return 1
		fi

	else
		cv1=`echo $correct_value | awk -F:: '{print $1}'`
		cv2=`echo $correct_value | awk -F:: '{print $2}'`

		if [ "$value" = "$cv1" ] || [ "$value" = "$cv2" ]
			then
			result=OK
			return 0
		else
			result="$value"
			return 1
		fi

	fi
}

simple_keys=`cut -d '=' -f1 $rules | grep -v '.x.'`

for key in $simple_keys
	do
	result=''
	check_key $key

	if [ $? -eq 1 ]
		then
		echo -n "$key "
	fi

done

complex_names=`cut -d '=' -f1 $rules | grep '.x.' | cut -d '.' -f1 | uniq`

for i in $complex_names
	do
	buf=`grep $i $cfg | awk -F. '{print $2}' | uniq`

	for count in $buf
		do
		complex_keys=`cut -d '=' -f1 $rules | grep '.x.' | grep $i | sed -e s/.x./.$count./g`
		sum=0
		for x in $complex_keys
			do
			check_key $x $count
			ret=$?
			sum=$((sum + ret))
		done

	done

	if [ $sum -gt 0 ]
		then
		echo -n "$i "
	fi

done

for i in `grep "unknown" $cfg`
	do
	echo -n `echo $i | cut -d '=' -f1`" "
done

#rm $cfg 2>/dev/null
echo
echo `date +%F\ %T` 'CHECK ['$$']:'" ends" >> $log
