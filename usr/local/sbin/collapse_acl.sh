#!/bin/bash

if [ -z $1 ]
	then
	exit 1
fi

if [ ! -s $1 ]
	then
	exit 1
fi


file="/tmp/`date +%s%N`.tmp"

grep "acl" $1 | grep -v "cpu" | grep -v "impb" > $file
ac=`cat $file | cut -d '.' -f2 | uniq`
netbios_filter=0

for i in $ac
	do
	type=`grep "acl.$i.type" $file | cut -d '=' -f2 | awk -F_ '{print $1"_"$2}'`

	case $type in
		"packet_content")	mask=`grep "acl.$i.mask" $file | cut -d '=' -f2 | awk '{print $1"_"$2"_"$3"_"$4}'`
					netbios_filter=6

					if [ "$mask" = 'l4_2_0xFFFF_' ] || [ "$mask" = '0x0_0x0_0xffff0000_0x0' ]
						then
						netbios_filter=$((netbios_filter - 1))
					fi

					access_id=`grep "acl.$i.access_id" $file | cut -d '.' -f4 | uniq`
					ports=''

					for j in $access_id
						do
						condition=`grep "acl.$i.access_id.$j.condition" $file | cut -d '=' -f2 | sed -e s/0x//g -e 's/^0\+//g'`
						p=`grep acl.$i.access_id.$j.ports $file | cut -d '=' -f2`

						if [ "$condition" != "87" ] && [ "$condition" != "89" ] && [ "$condition" != "8a" ] && [ "$condition" != "8b" ] && [ "$condition" != "1bd" ]
							then
							echo "acl_unknown_l4=$condition"
						fi

						if [ $j -eq 1 ]
							then
							ports=$p
						fi

						if [ "$p" = "$ports" ]
							then
							netbios_filter=$((netbios_filter - 1))
						fi

					done

					if [ $netbios_filter -eq 0 ]
						then
						echo "netbios_filter=$ports"
					else
						echo "netbios_filter="
					fi;;

		"ethernet.ethernet_type") 	access_id=`grep "acl.$i.access_id" $file | cut -d '.' -f4 | uniq`

	                                        for j in $access_id
        	                                        do
                	                                condition=`grep "acl.$i.access_id.$j.condition" $file | cut -d '=' -f2`
							ports=`grep "acl.$i.access_id.$j.ports" $file | cut -d '=' -f2`

							case $condition in
								"0x800")	echo "acl_ip=$ports";;
								"0x806")	echo "acl_arp=$ports";;
								"0x0800")	echo "acl_ip=$ports";;
								"0x0806")	echo "acl_arp=$ports";;
								"0x8863")	echo "acl_padx=$ports";;
								"0x8864")	echo "acl_pppoe=$ports";;
								"0x9000")	echo "acl_lbd=$ports";;
								*) echo "acl_unknown_ethertype=$condition";;
							esac

	                                        done;;

		"ethernet.source_mac")	mask=`grep "acl.$i.mask" $file | cut -d '=' -f2 | sed -e 's/ //g'`
					deny=2

					if [ "$mask" = "00-00-00-00-00-00" ]
						then
						deny=$((deny - 1))
					fi

					condition=`grep "acl.$i.access_id.1.condition" $file | cut -d '=' -f2 | sed -e 's/ //g'`

					if [ "$condition" = "00-00-00-00-00-00" ]
                                                then
                                                deny=$((deny - 1))
                                        	else
						echo "acl_unknown_mac_filter=$condition"
					fi

					ports=`grep "acl.$i.access_id.1.ports" $file | cut -d '=' -f2`

					if [ $deny -eq 0 ]
						then
						echo "acl_deny=$ports"
					else
						echo "acl_deny="
					fi;;

		*)	echo "acl_unknown_type=$type";;

	esac

done

grep "cpu_acl" $1 > $file
ac=`cat $file | cut -d '.' -f2 | uniq`

for i in $ac
	do
	type=`grep "cpu_acl.$i.type" $file | cut -d '=' -f2 | sed -e 's/ //g'`

	if [ "$type" != "ip.destination_ip" ] && [ "$type" != "ip.destination_ip_mask" ]
		then
		echo "cpu_acl_unknown_type=$type"
		continue
	fi

	mask=`grep "cpu_acl.$i.mask" $file | cut -d '=' -f2 | sed -e 's/ //g'`

	case $mask in

		"255.255.255.255")	access_id=`grep "cpu_acl.$i.access_id" $file | cut -d '.' -f4 | uniq`
					system=4

					for j in $access_id
						do
						condition=`grep "cpu_acl.$i.access_id.$j.condition" $file | cut -d '=' -f2 | sed -e 's/ //g'`

						if [ "$condition" = "224.0.0.1" ] || [ "$condition" = "224.0.0.2" ]
							then
							system=$((system - 1))
							else
							echo "cpu_acl_unknown_mcast_permit=$condition"
						fi

						p=`grep "cpu_acl.$i.access_id.$j.ports" $file | cut -d '=' -f2`

						if [ $j -eq 1 ]
							then
							ports=$p
						fi

						if [ "$p" = "$ports" ]
							then
							system=$((system - 1))
						fi

					done

					if [ "$2" = "3526" ]
						then
						ports='1-26'
					fi

					if [ $system -eq 0 ]
						then
							echo "cpu_acl.system=$ports"
						else
							echo "cpu_acl.system="
					fi;;

		"255.255.0.0")	subnet=`grep "cpu_acl.$i.access_id.1.condition" $file | cut -d '=' -f2 | sed -e 's/ //g'`
				ports=`grep "cpu_acl.$i.access_id.1.ports" $file | cut -d '=' -f2`
				iptv_permit=0

				if [ "$2" = "3526" ]
                                	then
					ports='1-26'
				fi

				if [ "$subnet" = "224.5.0.0" ]
					then
					iptv_permit=1
				else
					echo "cpu_acl_unknown_mcast_net_permit=$subnet"
				fi

				if [ $iptv_permit -eq 0 ]
					then
					echo "cpu_acl.iptv="
					else
					echo "cpu_acl.iptv=$ports"
				fi;;

		"240.0.0.0")	subnet=`grep "cpu_acl.$i.access_id.1.condition" $file | cut -d '=' -f2 | sed -e 's/ //g'`
                                ports=`grep "cpu_acl.$i.access_id.1.ports" $file | cut -d '=' -f2`

                                if [ "$2" = "3526" ]
                                        then
                                        ports='1-26'
                                fi

                                if [ "$subnet" = "224.0.0.0" ]
                                        then
                                        echo "cpu_acl.deny_igmp=$ports"
                                else
                                        echo "cpu_acl.deny_igmp="
                                fi;;
	esac

done

rm -f $file
