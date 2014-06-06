#!/bin/bash

if [ -z $1 ]
	then
	exit 0
fi

ip=$1
rules=$2
trunk=$3
access=$4
port_count=`echo $5 | sed -e s/://`
args=''
count=0
enum_pars=`cat $rules | grep -v '#' | grep '\.x\.' | cut -d. -f1 | uniq`
raw_fix='/tmp/'`date +%s%N`'-fix'
not_access=`/usr/local/sbin/invert_string_interval.sh $access $port_count`
not_trunk=`/usr/local/sbin/invert_string_interval.sh $trunk $port_count`

# Traffic control
traf_control_thold=`grep traffic_control_bcast_threshold $rules | cut -d= -f2`
traffic_control_trap="config traffic control_trap both"
traffic_control_string="config traffic control $access broadcast enable multicast enable unicast disable action shutdown threshold $traf_control_thold time_interval 5 countdown 0\nconfig traffic control $trunk broadcast disable multicast disable unicast disable"

# LBD
if [ "`grep lbd_state $rules | cut -d= -f2`" = "enable" ]
	then
	lbd_state="enable loopdetect"
	else
	lbd_state="disable loopdetect"
fi


lbd_on="config loopdetect ports $access state enabled"
lbd_off="config loopdetect ports $not_access state disabled"

# Safeguard
sg_state=`grep safeguard_state $rules | cut -d= -f2`
sg_rise=`grep safeguard_rising $rules | cut -d= -f2`
sg_fall=`grep safeguard_falling $rules | cut -d= -f2`

if [ "`grep safeguard_trap $rules | cut -d= -f2`" = "yes" ]
	then
	sg_trap="enable"
	else
	sg_trap="disable"
fi

safeguard_string="config safeguard_engine state $sg_state cpu_utilization rising_threshold $sg_rise falling_threshold $sg_fall trap_log $sg_trap mode fuzzy"

# Other
snmp_traps="enable snmp traps\nenable snmp authenticate traps"
link_trap="enable snmp linkchange_traps\nconfig snmp linkchange_traps ports all enable"
dhcp_local_relay="disable dhcp_local_relay"
dhcp_snooping="disable address_binding dhcp_snoop"
dhcp_screening="config filter dhcp_server ports $access state enable"
impb_trap="enable address_binding trap_log"
cpu_interface_filtering="enable cpu_interface_filtering"
arp_aging_time="config arp_aging time `grep arp_aging_time $rules | cut -d= -f2`"

# SNTP
sntp_addr1=`grep sntp_primary $rules | cut -d= -f2 | awk -F:: '{print $1}'`
sntp_addr2=`grep sntp_primary $rules | cut -d= -f2 | awk -F:: '{print $2}'`
sntp_string="enable sntp\nconfig sntp primary $sntp_addr1 secondary $sntp_addr2 poll-inteval 720"

# IGMP acc auth
igmp_acc_auth_enabled="config igmp access_authentication ports $access state enable"
igmp_acc_auth_disabled="config igmp access_authentication ports $not_access state disable"

# Mcast filter
range1="config limited_multicast_addr ports $access add profile_id 1\nconfig limited_multicast_addr ports $not_access delete profile_id 1"
range2="config limited_multicast_addr ports $access add profile_id 2\nconfig limited_multicast_addr ports $not_access delete profile_id 2"
range3="config limited_multicast_addr ports $access add profile_id 3\nconfig limited_multicast_addr ports $not_access delete profile_id 3"
range4="config limited_multicast_addr ports $access add profile_id 4\nconfig limited_multicast_addr ports $not_access delete profile_id 4"
range5="config limited_multicast_addr ports $access add profile_id 5\nconfig limited_multicast_addr ports $not_access delete profile_id 5"



for i in $@
	do

	case $i in
		"traffic_control_trap")			echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_bcast")		echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_mcast")		echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_bcast_threshold")	echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_mcast_threshold")	echo -e "$traffic_control_string" >> $raw_fix;;
		"link_trap")				echo -e "$link_trap" >> $raw_fix;;
		"lbd_state")				echo -e "$lbd_state" >> $raw_fix;;
		"lbd_on")				echo -e "$lbd_on" >> $raw_fix;;
		"lbd_off")				echo -e "$lbd_off" >> $raw_fix;;
		"safeguard_state")			echo -e "$safeguard_string" >> $raw_fix;;
		"safeguard_trap")			echo -e "$safeguard_string" >> $raw_fix;;
		"safeguard_rising")			echo -e "$safeguard_string" >> $raw_fix;;
		"safeguard_falling")			echo -e "$safeguard_string" >> $raw_fix;;
		"snmp_traps")				echo -e "$snmp_traps" >> $raw_fix;;
		"dhcp_local_relay")			echo -e "$dhcp_local_relay" >> $raw_fix;;
		"dhcp_snooping")			echo -e "$dhcp_snooping" >> $raw_fix;;
		"dhcp_screening")			echo -e "$dhcp_screening" >> $raw_fix;;
		"impb_trap")				echo -e "$impb_trap" >> $raw_fix;;
		"cpu_interface_filtering")		echo -e "$cpu_interface_filter" >> $raw_fixing;;
		"arp_aging_time")			echo -e "$arp_aging_time" >> $raw_fix;;
		"sntp_state")				echo -e "$sntp_string" >> $raw_fix;;
		"sntp_primary")				echo -e "$sntp_string" >> $raw_fix;;
		"sntp_secondary")			echo -e "$sntp_string" >> $raw_fix;;
                "igmp_acc_auth_enabled")                echo -e "$igmp_acc_auth_enabled" >> $raw_fix;;
                "igmp_acc_auth_disabled")               echo -e "$igmp_acc_auth_disabled" >> $raw_fix;;
		"mcast_range.iptv1")			echo -e "$range1" >> $raw_fix;;
		"mcast_range.iptv2")			echo -e "$range2" >> $raw_fix;;
		"mcast_range.iptv3")			echo -e "$range3" >> $raw_fix;;
		"mcast_range.iptv4")			echo -e "$range4" >> $raw_fix;;
		"mcast_range.iptv5")			echo -e "$range5" >> $raw_fix;;
	esac

done

fix_cmd='/tmp/'`date +%s%N`'_fix'
cat $raw_fix | uniq
rm -f $rules $raw_fix

