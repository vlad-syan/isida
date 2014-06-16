#!/bin/bash

#	DES-3526

ip=$1
cfg_path=`grep 'tftp_root' /etc/isida/isida.conf | cut -d '=' -f2`
cfg=$cfg_path/$ip
path=/tmp
ascii=$path/$ip.ascii
vlan=$path/$ip.vlan
traf=$path/$ip.traf
syslog=$path/$ip.syslog
radius=$path/$ip.radius
snmp=$path/$ip.snmp
loopdetect=$path/$ip.lbd
filter=$path/$ip.filter
impb=$path/$ip.impb
sntp=$path/$ip.sntp
acl=$path/$ip.acl
ism=$path/$ip.ism
dry_acl=$path/$ip.dry_acl
dry_mcast=$path/$ip.dry_mcast

if [ ! -s $cfg ]
	then
	echo "Config file not found!"
	exit 1
fi

echo "model=DES-3526"
cat $cfg | col > $ascii
fw=`grep "Build" $ascii | awk -F"Build " '{print $2}'`
echo "firmware=$fw"
sysloc=`grep "system_location" $ascii | awk -F"system_location " '{print $2}'`
echo "system_location=$sysloc"

#=======================#
#			#
#      Trunk ports	#
#	      		#
#=======================#

grep "[config,create] vlan " $ascii > $vlan

if [[ `grep -c 'config vlan default delete 1-26' $vlan` = 1 ]]
	then
	trunk_ports=`grep default $vlan | grep add | awk '{print $6}'`
	echo 'trunk='$trunk_ports
else
	echo 'trunk='`grep 'config vlan default delete' $vlan | awk '{print $5}' | xargs -l -I{} /usr/local/sbin/invert_string_interval.sh {} 26`
fi

#=======================#
#	    		#
# 	VLAN list 	#
#	    		#
#=======================#

vlanid_list=`grep create $vlan | awk '{print $5}'`
vlan_name_list=`grep create $vlan | awk '{print $3}'`

for i in $vlan_name_list
	do
	untag=`grep $i $vlan | grep -w untagged | awk '{print $6}'`
	tag=`grep $i $vlan | grep -w tagged | awk '{print $6}'`
	if [ -z $untag ]; then untag=0; fi
	if [ -z $tag ]; then tag=0; fi
	echo 'vlan_name='$i
	echo $i'.untagged='$untag
	echo $i'.tagged='$tag
done

#=======================#
#		  	#
#    Traffic control	#
#		  	#
#=======================#

grep "traffic control" $ascii > $traf

traf_trap=`grep "control_trap" $traf | awk '{print $4}'`
traf_b_on=`grep -w "broadcast enable" $traf | awk '{print $4}'`
traf_m_on=`grep -w "multicast enable" $traf | awk '{print $4}'`
traf_b_threshold=`grep -w "broadcast enable" $traf | awk -Fthreshold '{print $2}' | awk '{print $1}'`
traf_m_threshold=`grep -w "multicast enable" $traf | awk -Fthreshold '{print $2}' | awk '{print $1}'`

echo 'traffic_control_trap='$traf_trap
echo 'traffic_control_bcast='$traf_b_on
echo 'traffic_control_mcast='$traf_m_on
echo 'traffic_control_bcast_threshold='$traf_b_threshold
echo 'traffic_control_mcast_threshold='$traf_m_threshold

#=======================#
#	 		#
# 	  Syslog	#
#	 		#
#=======================#

grep "syslog" $ascii > $syslog

if [ `grep -wc "enable syslog" $syslog` -gt 0 ]
	then
	echo 'syslog_enabled=yes'

	for i in `grep "host" $syslog | awk '{print $4}'`
		do
		syslog_ip=`grep "host $i" $syslog | awk -Fipaddress '{print $2}' | awk '{print $1}'`
		syslog_severity=`grep "host $i" $syslog | awk -Fseverity '{print $2}' | awk '{print $1}'`
		syslog_facility=`grep "host $i" $syslog | awk -Ffacility '{print $2}' | awk '{print $1}'`
		syslog_enabled=`grep "host $i" $syslog |awk -Fstate '{print $2}' | awk '{print $1}'`
		echo "syslog_host.$i.ip=$syslog_ip"
		echo "syslog_host.$i.severity=$syslog_severity"
		echo "syslog_host.$i.facility=$syslog_facility"
		echo "syslog_host.$i.state=$syslog_enabled"
	done

else
	echo 'syslog_enabled=no'
fi

#=======================#
#			#
#	  RADIUS	#
#			#
#=======================#

grep "radius" $ascii > $radius

for i in `grep "radius add" $radius | awk '{print $4}'`
	do
	radius_ip=`grep "radius add $i" $radius | awk '{print $5}'`
	radius_key=`grep "radius add $i" $radius | awk -Fkey '{print $2}' | awk '{print $1}'`
	radius_auth=`grep "radius add $i" $radius | awk -Fauth_port '{print $2}' | awk '{print $1}'`
	radius_acct=`grep "radius add $i" $radius | awk -Facct_port '{print $2}' | awk '{print $1}'`
	echo "radius.$i.ip=$radius_ip"
	echo "radius.$i.key=$radius_key"
	echo "radius.$i.auth=$radius_auth"
	echo "radius.$i.acct=$radius_acct"
done

timeout=`grep "radius parameter" $radius | awk -Ftimeout '{print $2}' | awk '{print $1}'`
retransmit=`grep "radius parameter" $radius | awk -Fretransmit '{print $2}' | awk '{print $1}'`
echo "radius_timeout=$timeout"
echo "radius_retransmit=$retransmit"

#=======================#
#			#
#	  SNMP		#
#			#
#=======================#


grep "snmp" $ascii | grep host > $snmp
grep "snmp" $ascii | grep traps >> $snmp
grep "configuration trap" $ascii >> $snmp

snmp_hosts=`grep -c "create snmp host" $snmp`

if [ $snmp_hosts -gt 1 ]
	then

	for (( i = 1; i <= snmp_hosts; i++ ))
		do
		snmp_ip=`grep "create snmp host" $snmp | sed -e $i'!d' | awk '{print $4}'`
		snmp_community=`grep "create snmp host" $snmp | sed -e $i'!d' | awk '{print $6}'`
		echo "snmp_host.$i.ip=$snmp_ip"
		echo "snmp_host.$i.community=$snmp_community"
	done

else
	snmp_ip=`grep "create snmp host" $snmp | awk '{print $4}'`
	snmp_community=`grep "create snmp host" $snmp | awk '{print $6}'`
	echo "snmp_host.1.ip=$snmp_ip"
	echo "snmp_host.1.community=$snmp_community"

fi

if [ `grep -c "enable snmp traps" $snmp` -gt 0 ]
	then
	echo "snmp_traps=yes"
else
	echo "snmp_traps=no"
fi

if [ "`grep 'linkchange' $snmp | awk '{print $1}'`" = "enable" ]
	then
	echo "link_trap=yes"
else
	echo "link_trap=no"
fi

if [ "`grep 'save' $snmp | awk '{print $5}'`" = "enable" ]
	then
	echo "cfg_save_trap=yes"
else
	echo "cfg_save_trap=no"
fi

#=======================#
#			#
#	Loopdetect	#
#			#
#=======================#

grep "loopdetect" $ascii > $loopdetect

if [ `grep -c "enable loopdetect" $loopdetect` -gt 0 ]
	then
	echo "lbd_state=enable"
else
	echo "lbd_state=disable"
fi

lbd_on=`grep "state enabled" $loopdetect | awk '{print $4}'`
lbd_off=`grep "state disabled" $loopdetect | awk '{print $4}'`
echo "lbd_on=$lbd_on"
echo "lbd_off=$lbd_off"

#=======================#
#			#
#    Safeguard engine   #
#			#
#=======================#

safeguard_str=`grep safeguard $ascii`
rise=`echo $safeguard_str | awk -Frising_threshold '{print $2}' | awk '{print $1}'`
fall=`echo $safeguard_str | awk -Ffalling_threshold '{print $2}' | awk '{print $1}'`
sg_state=`echo $safeguard_str | awk -Fstate '{print $2}' | awk '{print $1}'`
sg_trap=`echo $safeguard_str | awk -Ftrap_log '{print $2}' | awk '{print $1}'`
echo "safeguard_state=$sg_state"

if [ "$sg_trap" = "enable" ]
	then
	echo "safeguard_trap=yes"
else
	echo "safeguard_trap=no"
fi

echo "safeguard_rising=$rise"
echo "safeguard_falling=$fall"

#=======================#
#			#
#	  Filter	#
#			#
#=======================#


grep -w "filter" $ascii | grep "enable" > $filter
filter_dhcp=`grep "dhcp_server" $filter | awk '{print $5}'`
filter_netbios=`grep "netbios" $filter | awk '{print $4}'`
echo "dhcp_screening=$filter_dhcp"
echo "netbios_filter=$filter_netbios"

#=======================#
#			#
#	DHCP relay	#
#			#
#=======================#

dhcp_r=`grep "dhcp_relay" $ascii | awk '{print $1}'`
dhcp_l=`grep "dhcp_local_relay" $ascii | awk '{print $1}'`

if [ "$dhcp_r" = "enable" ]
	then
	echo "dhcp_relay=yes"
else
	echo "dhcp_relay=no"
fi

if [ "$dhcp_l" = "enable" ]
	then
	echo "dhcp_local_relay=yes"
else
	echo "dhcp_local_relay=no"
fi

#=======================#
#			#
#	  IMPB		$
#			#
#=======================#

grep "address_binding" $ascii > $impb
dhcp_s=`grep "dhcp_snoop" $impb | awk '{print $1}'`
impb_acl=`grep "acl_mode" $impb | awk '{print $1}'`
impb_arp=`grep "arp_inspection" $impb | awk '{print $1}'`
impb_trap=`grep "trap_log" $impb | awk '{print $1}'`
impb_ports=`grep "ip_mac" $impb | grep "config" | grep -v "allow_zeroip" | grep -v "loose" | awk -Fports '{print $2}' | awk '{print $1}'`
impb_loose=`grep "ip_mac" $impb | grep "config" | grep "loose" | awk -Fports '{print $2}' | awk '{print $1}'`
impb_zeroip=`grep "ip_mac" $impb | grep "config" | grep "allow_zeroip" | awk -Fports '{print $2}' | awk '{print $1}'`

if [ "$dhcp_s" = "enable" ]
	then
	echo "dhcp_snooping=yes"
else
	echo "dhcp_snooping=no"
fi

if [ "$impb_acl" = "enable" ]
	then
	echo "impb_acl_mode=yes"
else
	echo "impb_acl_mode=no"
fi

if [ "$impb_arp" = "enable" ]
	then
	echo "impb_arp_inspection=yes"
else
	echo "impb_arp_inspection=no"
fi

if [ "$impb_trap" = "enable" ]
	then
	echo "impb_trap=yes"
else
	echo "impb_trap=no"
fi

echo "impb_ports_on=$impb_ports"
echo "impb_ports_loose=$impb_loose"
echo "impb_ports_zeroip=$impb_zeroip"

#=======================#
#			#
#	  SNTP		#
#			#
#=======================#

grep "sntp" $ascii > $sntp

if [ `grep -c "enable" $sntp` -gt 0 ]
	then
	echo "sntp_state=enable"
else
	echo "sntp_state=disable"
fi

sntp_pri=`grep "config" $sntp | awk -Fprimary '{print $2}' | awk '{print $1}'`
sntp_sec=`grep "config" $sntp | awk -Fsecondary '{print $2}' | awk '{print $1}'`
echo "sntp_primary=$sntp_pri"
echo "sntp_secondary=$sntp_sec"

#=======================#
#			#
#	   ACL  	#
#			#
#=======================#

grep "access_profile" $ascii > $acl
rm -f $dry_acl 2>/dev/null

function parse_acl {

for i in $@
	do

	#-----------------------#
	#			#
	#	 ACL type	#
	#			#
	#-----------------------#

	if [ $cpu -eq 1 ]
		then
		pname="cpu_acl.$i"
		profile_type=`grep "create cpu" $acl | grep "profile_id $i" | awk -Faccess_profile '{print $2}' | awk '{print $1" "$2}'`
	else
		pname="acl.$i"
		profile_type=`grep "create" $acl | grep "profile_id $i" | awk -Faccess_profile '{print $2}' | awk '{print $1" "$2}'`
	fi

	echo "$pname.type=$profile_type" | sed -e 's/\ /./g' >> $dry_acl

	#-----------------------#
	#			#
	#     ACL condition	#
	#			#
	#-----------------------#

	ptype=`echo "$profile_type" | sed -e 's/_mask//g'`
	access_id_condition_list=`grep "profile_id $i add access_id" $acl | awk -F"$ptype" '{print $2}' | awk '{print $1}' | sort | uniq`
	if [ `echo $profile_type | grep -c "type"` -eq 0 ]
		then
		mask=`grep "create" $acl | grep -w "profile_id $i" | awk -F"$profile_type" '{print $2}' | awk '{print $1}'`
		echo "$pname.mask=$mask" >> $dry_acl
	fi

	count=0

	for j in $access_id_condition_list
		do
		count=$((count + 1))
		aname="$pname.access_id.$count"
		echo "$aname.condition=$j" >> $dry_acl

		#-----------------------#
		#			#
		#	ACL ports	#
		#			#
		#-----------------------#

		for x in {1..26}
			do
			ports[$x]='0'
		done

		access_id_ports=`grep "$access_id_condition_list" $acl | awk -Fport '{print $2}' | awk '{print $1}'`

		for y in $access_id_ports
			do
			ports[$y]='1'
		done

		plain=`echo ${ports[@]}`
		ports_str=`/usr/local/sbin/bitmask_to_interval.sh $plain`

		if [ -n "$ports_str" ]
			then
			echo "$aname.ports=$ports_str" >> $dry_acl
		fi

	done

done

}

access_profile_list=`grep "create" $acl | grep -v "cpu" | awk -Fprofile_id '{print $2}' | awk '{print $1}'`
cpu=0
parse_acl "$access_profile_list"

access_profile_list=`grep "create cpu" $acl | awk -Fprofile_id '{print $2}' | awk '{print $1}'`
cpu=1
parse_acl "$access_profile_list"

/usr/local/sbin/collapse_acl.sh $dry_acl 3526

if [ `grep -c "enable cpu_interface_filtering" $ascii` -gt 0 ]
	then
	echo "cpu_interface_filtering=yes"
else
	echo "cpu_interface_filtering=no"
fi

#=======================#
#			#
#     IGMP Snooping	#
#			#
#=======================#

rm -f $dry_mcast 2>/dev/null
grep "igmp" $ascii > $ism
grep "multicast_" $ascii >> $ism

if [ `grep -c "enable igmp_snooping" $ism` -gt 0 ]
	then
	echo "igmp_snooping=yes"
else
	echo "igmp_snooping=no"
fi

temp=`grep "create igmp_snooping multicast_vlan" $ism`
ism_name=`echo $temp | awk '{print $4}'`
ism_vid=`echo $temp | awk '{print $5}'`
echo "ism_vlan_name=$ism_name"
echo "$ism_name.tag=$ism_vid"
temp=`grep "config igmp_snooping multicast_vlan" $ism`
ism_source=`echo $temp | awk -Fsource_port '{print $2}' | awk '{print $1}'`
ism_member=`echo $temp | awk -Fmember_port '{print $2}' | awk '{print $1}'`
ism_state=`echo $temp | awk -Fstate '{print $2}' | awk '{print $1}'`
echo "$ism_name.state=$ism_state"
echo "$ism_name.member_ports=$ism_member"
echo "$ism_name.source_ports=$ism_source"
querier=`grep "querier" $ism | grep "state" | awk -Fstate '{print $2}' | awk '{print $1}'`
echo "$ism_name.querier_state=$querier"

for i in `grep "create multicast_range" $ism | awk '{print $3}'`
	do
	echo "mcast_range=$i" >> $dry_mcast
	range=`grep -w "create multicast_range $i" $ism | awk '{print $5"-"$7}'`
	echo "mcast_range.$i.addr=$range" >> $dry_mcast
	ports=`grep "config" $ism | grep $i | awk -Fports '{print $2}' | awk '{print $1}'`
	echo "mcast_range.$i.ports=$ports" >> $dry_mcast
done

/usr/local/sbin/collapse_mcast.sh $dry_mcast
#cat $dry_mcast

permit_access=`grep "access permit" $ism | awk -Fports '{print $2}' | awk '{print $1}'`
deny_access=`grep "access deny" $ism | awk -Fports '{print $2}' | awk '{print $1}'`
limited_mcast_enabled=`grep "limited" $ism | grep "state enable" | awk -Fports '{print $2}' | awk '{print $1}'`
limited_mcast_disabled=`grep "limited" $ism | grep "state disable" | awk -Fports '{print $2}' | awk '{print $1}'`
echo "limited_mcast_permit=$permit_access"
echo "limited_mcast_deny=$deny_access"
echo "limited_mcast_enabled=$limited_mcast_enabled"
echo "limited_mcast_disabled=$limited_mcast_disabled"
igmp_aa_enabled=`grep "access_authentication" $ism | grep "enable" | awk -Fports '{print $2}' | awk '{print $1}'`
igmp_aa_disabled=`grep "access_authentication" $ism | grep "disable" | awk -Fports '{print $2}' | awk '{print $1}'`
echo "igmp_acc_auth_enabled=$igmp_aa_enabled"
echo "igmp_acc_auth_disabled=$igmp_aa_disabled"


arp_time=`grep "arp_aging" $ascii | awk '{print $4}'`
echo "arp_aging_time=$arp_time"


rm -f $ascii $vlan $traf $syslog $radius $snmp $loopdetect $filter $impb $sntp $acl $ism $dry_acl $dry_mcast

