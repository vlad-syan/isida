#!/bin/bash


if [ -z $1 ]
	then
	exit 0
fi

source=`echo $1 | sed -e 's/,/ /g'`

for i in {1..32}
	do
	ports[$i]='0'
done

function parse_interval {

interval=$1
result=''
start=`echo $interval | awk -F- '{print $1}'`
end=`echo $interval | awk -F- '{print $2}'`

if [ -z $end ]
	then
	end=$start
fi

result=''

for (( i = start; i <= end; i++ ))
	do
	result=$result"$i "
done

}

fin=''

for int in $source
	do
	parse_interval $int
	fin=$fin"$result"
done

echo $fin
