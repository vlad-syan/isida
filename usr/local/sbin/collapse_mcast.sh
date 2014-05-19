#!/bin/bash

rules='/etc/isida/collapse_mcast.conf'

if [ -z $1 ]
        then
        exit 1
fi

if [ ! -s $1 ]
        then
        exit 1
fi


ranges=`grep 'mcast_range=' $1 | awk -F= '{print $2}'`

for i in $ranges
	do
	addr=`grep "mcast_range.$i.addr" $1 | awk -F= '{print $2}'`
	ports=`grep "mcast_range.$i.ports" $1 | awk -F= '{print $2}'`

	if [ ! -z "$addr" ]
		then
		name=`grep $addr $rules | cut -d '=' -f1`

		if [ ! -z "$ports" ]
			then

			if [ -z "$name" ]
				then
				echo "mcast_range.unknown.$addr=$ports"
				else
				echo "mcast_range.$name=$ports"
			fi

		fi

	fi

done
