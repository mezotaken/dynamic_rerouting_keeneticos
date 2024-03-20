#!/bin/sh
vpn_id="Wireguard1"
unblock_list="/opt/root/unblock.txt"

[ "$1" == "hook" ] || exit
[ "$id" == "$vpn_id" ] || exit

case ${layer}-${level} in
    link-running)
        # Create unblock table
        if [ -z "$(ipset list | grep unblock)" ]
        then
            logger "|=== > Unblock: create ip table"
            ipset create unblock hash:net -exist
        else
            ipset flush unblock
        fi

        # Fill unblock table
        while read line || [ -n "$line" ]; do
            [ -z "$line" ] && continue
            [ "${line:0:1}" = "#" ] && continue

            cidr=$(echo $line | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}')

            if [ ! -z "$cidr" ]; then
                ipset -exist add unblock $cidr
                continue
            fi

            range=$(echo $line | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

            if [ ! -z "$range" ]; then
                ipset -exist add unblock $range
                continue
            fi

            addr=$(echo $line | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

            if [ ! -z "$addr" ]; then
                ipset -exist add unblock $addr
                continue
            fi

            dig +short $line | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{system("ipset -exist add unblock "$1)}'

        done < $unblock_list


        # Create routing tables for marked packets
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
        # Delete routing tables for marked packets
        if [ -n "$(ip rule show | grep 1000:)" ]
        then
            logger "|=== > Unblock: del rule to $id"
            ip rule del table 1
        fi
        # Probably not required since table dissapears on interface disable
        if [ -n "$(ip route list table 1)" ]
        then
            logger "|=== > Unblock: del route to $id"
            ip route flush table 1
        fi

        # Enable HW NAT
        sysctl -w net.netfilter.nf_conntrack_fastnat=1
    ;;
esac