#!/bin/sh

unblock_list="/opt/root/unblock.txt"

# Create or flush unblock table
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