#!/bin/bash

if [ -z $1 ]
	then
	exit 0
fi

if [ -s $2 ]
	then
	echo "#!/usr/bin/expect -f"
	echo "set timeout $3"
	echo "log_user 0"
	echo "spawn telnet $1"
	echo 'expect "ame:" {send "admin\r"}'
	echo 'expect "ord:" {send "Masterok\r"}'
	cat $2 | xargs -l -I{} echo 'expect "#" {send "'{}'\r"}'
	echo 'expect "#" {send "logout\r"}'
	echo "expect eof"
	echo "log_user 1"
fi
