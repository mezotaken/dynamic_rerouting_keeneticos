#!/bin/sh

vpn_id="Wireguard1"

[ "$1" == "hook" ] || exit
[ "$id" == "$vpn_id" ] || exit

case ${layer}-${level} in
    link-running)

        /opt/bin/recreate_ip_set.sh

        # Create routing rules for marked packets
        if [ -z "$(ip rule show | grep 1000:)" ]
        then
            logger "|=== > Unblock: add rule to $id"
            ip rule add fwmark 1 table 1 priority 1000
        fi

        if [ -z "$(ip route list table 1)" ]
        then
            logger "|=== > Unblock: add route to $id"
            ip route add default dev $system_name table 1
        fi

        # Disable HW NAT
        sysctl -w net.netfilter.nf_conntrack_fastnat=0

    ;;
    link-disabled)

        # Delete unblock table
        if [ -n "$(ipset list | grep unblock)" ]
        then
            logger "|=== > Unblock: destroy ip table"
            ipset destroy unblock
        fi
        # Delete routing rules for marked packets
        if [ -n "$(ip rule show | grep 1000:)" ]
        then
            logger "|=== > Unblock: del rule to $id"
            ip rule del table 1
        fi
        if [ -n "$(ip route list table 1)" ]
        then
            logger "|=== > Unblock: del route to $id"
            ip route flush table 1
        fi

        # Enable HW NAT
        sysctl -w net.netfilter.nf_conntrack_fastnat=1

    ;;
esac