#!/bin/sh

[ "$type" == "ip6tables" ] && exit 0
[ "$table" != "mangle" ] && exit 0
[ -z "$(iptables -t mangle -L | grep unblock)" ] || exit 0


# May work before the other script?
if [ -z "$(ipset list | grep unblock)" ]
then
    logger "|=== > Unblock: create ip table"
    ipset create unblock hash:net -exist
fi
iptables -w -A PREROUTING -t mangle -m set --match-set unblock dst,src -j MARK --set-mark 1