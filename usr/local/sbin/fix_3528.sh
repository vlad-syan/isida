#!/bin/bash

if [ -z $1 ]
	then
	exit 0
fi

ip=$1
rules=$2
trunk=$3
access=$4
general_rules='/etc/isida/isida.conf'
get_uplink=`grep 'uplink' $general_rules | cut -d= -f2 | sed -e s/%ip/$ip/`
ism_vlanid=`grep 'ism_vlanid' $general_rules | cut -d= -f2`
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
	traffic_control_string=$traffic_control_string"\nconfig traffic control $i broadcast enable multicast enable unicast disable action drop broadcast_threshold $traf_control_thold multicast_threshold 128 unicast_threshold 131072 countdown 0 time_interval 5"
done

for i in $not_access_ports
	do
	traffic_control_string=$traffic_control_string"\nconfig traffic control $i broadcast disable multicast disable unicast disable action drop broadcast_threshold $traf_control_thold multicast_threshold 128 unicast_threshold 131072 countdown 0 time_interval 5"
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

safeguard_string="config safeguard_engine state $sg_state utilization rising $sg_rise falling $sg_fall trap_log $sg_trap mode fuzzy"

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
igmp_snooping="enable igmp_snooping"
link_trap="enable snmp linkchange_traps\nconfig snmp linkchange_traps ports 1-28 enable"

# SNTP
sntp_addr1=`grep sntp_primary $rules | cut -d= -f2 | awk -F:: '{print $1}'`
sntp_addr2=`grep sntp_primary $rules | cut -d= -f2 | awk -F:: '{print $2}'`
sntp_string="enable sntp\nconfig sntp primary $sntp_addr1 secondary $sntp_addr2 poll-interval 720\nconfig sntp primary $sntp_addr2 secondary $sntp_addr1"

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
#syslog_severity=`grep 'syslog_host.x.severity' $rules | cut -d= -f2`
syslog_facility=`grep 'syslog_host.x.facility' $rules | cut -d= -f2`
syslog_state=`grep 'syslog_host.x.state' $rules | cut -d= -f2`
syslog_del="delete syslog host 2"
syslog_add="create syslog host 2 ipaddress $syslog_ip severity debug facility $syslog_facility state $syslog_state"
syslog_enabled="enable_syslog"

# SNMP
snmp_ip=`grep 'snmp_host.x.ip' $rules | cut -d= -f2`
snmp_community=`grep 'snmp_host.x.community' $rules | cut -d= -f2`
snmp_del="delete snmp host $snmp_ip\ndelete snmp host 192.168.1.120"
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
radius_params="config radius 1 timeout $radius_timeout retransmit $radius_retransmit"


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
		"cpu_interface_filtering")		echo -e "$cpu_interface_filtering" >> $raw_fixing;;
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
                "syslog_host")                          echo -e "$syslog_del\n$syslog_add" >> $raw_fix;;
                "snmp_host")                            echo -e "$snmp_del\n$snmp_add" >> $raw_fix;;
                "radius")                               echo -e "$radius_del\n$radius_add\n$radius_params" >> $raw_fix;;
                "radius_retransmit")                    echo -e "$radius_params" >> $raw_fix;;
                "radius_timeout")                       echo -e "$radius_params" >> $raw_fix;;
                "igmp_snooping")                        echo -e "$igmp_snooping" >> $raw_fix;;
                "syslog_enabled")                       echo -e "$syslog_enabled" >> $raw_fix;;
                "ism")                                  if [ `/usr/local/sbin/ping_equip.sh $ip` -eq 1 ]
                                                                then
                                                                ism_prefix='.1.3.6.1.4.1.171.12.64.3.1.1'
                                                                ism_name=`snmpget -v2c -c dlread -Ovq $ip $ism_prefix.2.$ism_vlanid | sed -e s/\"//g`
                                                                uplink=`$get_uplink`
								raw_tagmember=`snmpget -v2c -c dlread -Ovq $ip $ism_prefix.5.$ism_vlanid | sed -e s/\"//g | awk '{print $1 $2 $3 $4}' | xargs -l /usr/local/sbin/portconv.sh`
								raw_member=`snmpget -v2c -c dlread -Ovq $ip $ism_prefix.4.$ism_vlanid | sed -e s/\"//g | awk '{print $1 $2 $3 $4}' | xargs -l /usr/local/sbin/portconv.sh`
								raw_source=`snmpget -v2c -c dlread -Ovq $ip $ism_prefix.3.$ism_vlanid | sed -e s/\"//g | awk '{print $1 $2 $3 $4}' | xargs -l /usr/local/sbin/portconv.sh`
								tagmember=`/usr/local/sbin/string_to_bitmask.sh $raw_tagmember | xargs -l /usr/local/sbin/bitmask_to_interval.sh`
								source=`/usr/local/sbin/string_to_bitmask.sh $raw_source | xargs -l /usr/local/sbin/bitmask_to_interval.sh`
                                                                echo -e "config igmp_snooping multicast_vlan $ism_name del tag $tagmember" >> $raw_fix
                                                                echo -e "config igmp_snooping multicast_vlan $ism_name del source $source" >> $raw_fix
                                                                detailed_trunk=`/usr/local/sbin/interval_to_string.sh $trunk`
								del_member_raw=''

								for i in $detailed_trunk
									do

									if [ "`echo $raw_member | grep $i`" ]
										then
										del_member_raw=$del_member_raw" $i"
									fi

								done

								if [ -n "$del_member_raw" ]
									then
									del_member=`/usr/local/sbin/string_to_bitmask.sh $del_member_raw | xargs -l /usr/local/sbin/bitmask_to_interval.sh`
									echo -e "config igmp_snooping multicast_vlan $ism_name del member $del_member" >> $raw_fix
								fi

                                                                new_source=$uplink
								new_tagmember=`echo $detailed_trunk | sed -e s/$uplink// | xargs -l /usr/local/sbin/string_to_bitmask.sh | xargs -l /usr/local/sbin/bitmask_to_interval.sh`
                                                                echo -e "config igmp_snooping multicast_vlan $ism_name add source $new_source" >> $raw_fix
                                                                echo -e "config igmp_snooping multicast_vlan $ism_name add tag $new_tagmember" >> $raw_fix
                                                        fi;;
 	esac

done

fix_cmd='/tmp/'`date +%s%N`'_fix'

if [ -s $raw_fix ]
        then
        echo "save" >> $raw_fix
fi

cat $raw_fix | uniq 
rm -f $rules $raw_fix
