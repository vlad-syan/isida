#!/bin/bash

ip=$1

if [ "`/usr/local/sbin/ping_equip.sh $ip`" = "0" ]
	then
	exit 0
fi

snmpwalk -v2c -Ovqn -c dlread $ip .1.3.6.1.2.1.1.2 | sed -e 's/.1.3.6.1.4.1.//'
