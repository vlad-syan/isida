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
access_ports="`/usr/local/sbin/interval_to_string.sh $access`"
not_access_ports="`/usr/local/sbin/interval_to_string.sh $not_access`"
traffic_control_string=""

for i in $access_ports
	do
	traffic_control_string=$traffic_control_string"\nconfig traffic control $i broadcast enable multicast enable action drop threshold $traf_control_thold countdown 0 time_interval 5"
done

for i in $not_access_ports
	do
	traffic_control_string=$traffic_control_string"\nconfig traffic control $i broadcast disable multicast disable action drop threshold $traf_control_thold countdown 0 time_interval 5"
done

# LBD
if [ "`grep lbd_state $rules | cut -d= -f2`" = "enable" ]
	then
	lbd_state="enable loopdetect"
	else
	lbd_state="disable loopdetect"
fi

lbd_trap="config loopdetect trap `grep lbd_trap $rules | cut -d= -f2`"
lbd_on=""

for i in $access_ports
	do
	lbd_on=$lbd_on"\nconfig loopdetect ports $i state enable"
done

lbd_off=""

for i in $not_access_ports
	do
	lbd_off=$lbd_off"\nconfig loopdetect ports $i state disable"
done

#lbd_off="config loopdetect ports $not_access state disabled"

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
dhcp_local_relay="disable dhcp_local_relay"
dhcp_snooping="disable address_binding dhcp_snoop"
impb_acl_mode="disable address_binding acl_mode"
dhcp_screening="config filter dhcp_server ports all state disable\nconfig filter dhcp_server ports $access state enable"
netbios_filter="config filter netbios all state disable\nconfig filter netbios $access state enable"
impb_trap="enable address_binding trap_log"
cpu_interface_filtering="enable cpu_interface_filtering"
arp_aging_time="config arp_aging time `grep arp_aging_time $rules | cut -d= -f2`"
link_trap="enable snmp linkchange_traps\nconfig snmp linkchange_traps ports 1-28 enable"
igmp_snooping="enable igmp_snooping"

# SNTP
sntp_addr1=`grep sntp_primary $rules | cut -d= -f2 | awk -F:: '{print $1}'`
sntp_addr2=`grep sntp_primary $rules | cut -d= -f2 | awk -F:: '{print $2}'`
sntp_string="enable sntp\nconfig sntp primary $sntp_addr1 secondary $sntp_addr2 poll-inteval 720"

# IGMP acc auth
igmp_acc_auth_enabled="config igmp access_authentication ports $access state enable"
igmp_acc_auth_disabled="config igmp access_authentication ports $not_access state disable"

# Limited mcast
range1="config limited_multicast_addr ports $access add profile_id 1\nconfig limited_multicast_addr ports $not_access delete profile_id 1"
range2="config limited_multicast_addr ports $access add profile_id 2\nconfig limited_multicast_addr ports $not_access delete profile_id 2"
range3="config limited_multicast_addr ports $access add profile_id 3\nconfig limited_multicast_addr ports $not_access delete profile_id 3"
range4="config limited_multicast_addr ports $access add profile_id 4\nconfig limited_multicast_addr ports $not_access delete profile_id 4"
range5="config limited_multicast_addr ports $access add profile_id 5\nconfig limited_multicast_addr ports $not_access delete profile_id 5"
limited_access="config limited_multicast_addr ports $access access permit"
limited_deny="config limited_multicast_addr ports $trunk access deny"
# SYSLOG
syslog_ip=`grep 'syslog_host.x.ip' $rules | cut -d= -f2`
syslog_severity=`grep 'syslog_host.x.severity' $rules | cut -d= -f2`
syslog_facility=`grep 'syslog_host.x.facility' $rules | cut -d= -f2`
syslog_state=`grep 'syslog_host.x.state' $rules | cut -d= -f2`
syslog_del="delete syslog host 2"
syslog_add="create syslog host 2 ipaddress $syslog_ip severity $syslog_severity facility $syslog_facility state $syslog_state"
syslog_enabled="enable_syslog"

# SNMP
snmp_ip=`grep 'snmp_host.x.ip' $rules | cut -d= -f2`
snmp_community=`grep 'snmp_host.x.community' $rules | cut -d= -f2`
snmp_del="delete snmp host $snmp_ip"
snmp_add="create snmp host $snmp_ip v2c $snmp_community"

# RADIUS
radius_ip=`grep 'radius.x.ip' $rules | cut -d= -f2`
radius_key=`grep 'radius.x.key' $rules | cut -d= -f2`
radius_auth=`grep 'radius.x.auth' $rules | cut -d= -f2`
radius_acct=`grep 'radius.x.acct' $rules | cut -d= -f2`
radius_retransmit=`grep 'radius_retransmit' $rules | cut -d= -f2`
radius_timeout=`grep 'radius_timeout' $rules | cut -d= -f2`
radius_del="config radius delete 1"
radius_add="config radius add 1 $radius_ip key $radius_key auth_port $radius_auth acct_port $radius_acct"
radius_params="config radius parameter timeout $radius_timeout retransmit $radius_retransmit"


for i in $@
	do

	case $i in
		"traffic_control_trap")			echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_bcast")		echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_mcast")		echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_bcast_threshold")	echo -e "$traffic_control_string" >> $raw_fix;;
		"traffic_control_mcast_threshold")	echo -e "$traffic_control_string" >> $raw_fix;;
		"lbd_state")				echo -e "$lbd_state" >> $raw_fix;;
		"lbd_on")				echo -e "$lbd_on" >> $raw_fix;;
		"lbd_off")				echo -e "$lbd_off" >> $raw_fix;;
		"lbd_trap")				echo -e "$lbd_trap" >> $raw_fix;;
		"safeguard_state")			echo -e "$safeguard_string" >> $raw_fix;;
		"safeguard_trap")			echo -e "$safeguard_string" >> $raw_fix;;
		"safeguard_rising")			echo -e "$safeguard_string" >> $raw_fix;;
		"safeguard_falling")			echo -e "$safeguard_string" >> $raw_fix;;
		"snmp_traps")				echo -e "$snmp_traps" >> $raw_fix;;
		"dhcp_local_relay")			echo -e "$dhcp_local_relay" >> $raw_fix;;
		"dhcp_snooping")			echo -e "$dhcp_snooping" >> $raw_fix;;
		"impb_acl_mode")			echo -e "$impb_acl_mode" >> $raw_fix;;
		"dhcp_screening")			echo -e "$dhcp_screening" >> $raw_fix;;
		"netbios_filter")			echo -e "$netbios_filter" >> $raw_fix;;
		"impb_trap")				echo -e "$impb_trap" >> $raw_fix;;
		"cpu_interface_filtering")		echo -e "$cpu_interface_filter" >> $raw_fixing;;
		"arp_aging_time")			echo -e "$arp_aging_time" >> $raw_fix;;
		"sntp_state")				echo -e "$sntp_string" >> $raw_fix;;
		"sntp_primary")				echo -e "$sntp_string" >> $raw_fix;;
		"sntp_secondary")			echo -e "$sntp_string" >> $raw_fix;;
		"link_trap")				echo -e "$link_trap" >> $raw_fix;;
                "mcast_range.iptv1")                    echo -e "$range1\n$limited_access\n$limited_deny" >> $raw_fix;;
                "mcast_range.iptv2")                    echo -e "$range2\n$limited_access\n$limited_deny" >> $raw_fix;;
                "mcast_range.iptv3")                    echo -e "$range3\n$limited_access\n$limited_deny" >> $raw_fix;;
                "mcast_range.iptv4")                    echo -e "$range4\n$limited_access\n$limited_deny" >> $raw_fix;;
                "mcast_range.iptv5")                    echo -e "$range5\n$limited_access\n$limited_deny" >> $raw_fix;;
                "igmp_acc_auth_enabled")                echo -e "$igmp_acc_auth_enabled" >> $raw_fix;;
                "igmp_acc_auth_disabled")               echo -e "$igmp_acc_auth_disabled" >> $raw_fix;;
                "syslog")                               echo -e "$syslog_del\n$syslog_add" >> $raw_fix;;
                "snmp")                                 echo -e "$snmp_del\n$snmp_add" >> $raw_fix;;
                "radius")                               echo -e "$radius_del\n$radius_add" >> $raw_fix;;
                "radius_retransmit")                    echo -e "$radius_params" >> $raw_fix;;
                "radius_timeout")                       echo -e "$radius_params" >> $raw_fix;;
                "igmp_snooping")                        echo -e "$igmp_snooping" >> $raw_fix;;
                "syslog_enabled")                       echo -e "$syslog_enabled" >> $raw_fix;;
	esac

done

fix_cmd='/tmp/'`date +%s%N`'_fix'

if [ -s $raw_fix ]
	then
	echo "save" >> $raw_fix
fi

cat $raw_fix | uniq 
rm -f $rules $raw_fix

