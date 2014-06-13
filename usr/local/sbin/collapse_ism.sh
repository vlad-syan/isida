#!/bin/bash

if [ -z $1 ]
	then
	exit 1
fi

cfg=$1
name=`grep "ism_vlan_name" $cfg | cut -d '=' -f2`

for i in $name
	do
	index=`grep "$i.tag=" $cfg | cut -d '=' -f2`
	untagged=`grep "$i.member_ports" $cfg | cut -d '=' -f2`
	source=`grep "$i.source_ports" $cfg | awk -F= '{print $2}'`
	buf=`grep -e "$i.tagged_ports" -e "source_ports" $cfg | cut -d '=' -f2 | xargs -l /usr/local/sbin/interval_to_string.sh | sort -n`
	tagged=`/usr/local/sbin/string_to_bitmask.sh "$buf" | xargs -l /usr/local/sbin/bitmask_to_interval.sh`
	echo "ism.$index.untagged=$untagged"
	echo "ism.$index.tagged=$tagged"
	echo "ism.$index.source=$source"
done

