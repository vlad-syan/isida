#!/bin/bash

if [ -z $1 ]
	then
	exit 1
fi

if [ "$1" = "256.256.256.256" ]
	then
	echo 0
	exit 0
	else
	res=`ping $1 -c 1 -W 1 -q | awk -F, '{print $2}' | awk '{print $1}'`
	echo $res
fi
