#!/bin/bash


if [ -z "$1" ]
	then
	exit 0
fi


for i in {1..28}
	do
	ports[$i]='0'
done

for i in $@
	do
	ports[$i]='1'
done

echo "${ports[@]}"
